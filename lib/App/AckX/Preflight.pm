package App::AckX::Preflight;

use 5.008008;

use strict;
use warnings;

use App::Ack ();
use App::AckX::Preflight::Util ();
use Cwd ();
use File::Spec;
use Module::Pluggable::Object 5.2;
use Pod::Usage ();
use Text::ParseWords ();

our $VERSION;
our $COPYRIGHT;

use constant DEVELOPMENT => grep { m{ \b blib \b }smx } @INC;

use constant IS_VMS	=> 'VMS' eq $^O;
use constant IS_WINDOWS	=> { map { $_ => 1 } qw{ dos MSWin32 } }->{$^O};

BEGIN {

    App::AckX::Preflight::Util->import( ':all' );

    $VERSION = '0.000_018';
    $COPYRIGHT = 'Copyright (C) 2018 by Thomas R. Wyant, III';

    IS_WINDOWS
	and require Win32;
}

use constant PLUGIN_SEARCH_PATH	=> join '::', __PACKAGE__, 'Plugin';
use constant PLUGIN_MAX_DEPTH	=> do {
    my @parts = split qr{ :: }smx, PLUGIN_SEARCH_PATH;
    1 + @parts;
};

{
    my %default;

    BEGIN {
	%default = (
	    global	=> IS_VMS ? undef :	# TODO what, exactly?
		IS_WINDOWS ? Win32::CSIDL_COMMON_APPDATA() :
		'/etc',
	    home	=> IS_VMS ? $ENV{'SYS$LOGIN'} :
		IS_WINDOWS ? Win32::CSIDL_APPDATA() :
		$ENV{HOME},
	);
    }

    sub new {
	my ( $class, %arg ) = @_;

	ref $class
	    and %arg = ( %{ $class }, %arg );

	foreach ( keys %arg ) {
	    exists $default{$_}
		or __die( "Argument '$_' not supported" );
	}

	foreach ( keys %default ) {
	    defined $arg{$_}
		or $arg{$_} = $default{$_};
	}

	foreach ( qw{ global home } ) {
	    -d $arg{$_}
		or __die( "Argument '$_' must be a directory" );
	}

	$arg{disable}	= {};

	return bless \%arg, ref $class || $class;
    }

    sub global {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{global};
    }

    sub home {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{home};
    }
}

sub __inject {
    my ( $self, @arg ) = @_;
    push @{ $self->{inject} }, @arg;
    return;
}

sub run {
    my ( $self ) = @_;

    ref $self
	or $self = $self->new();

    my %opt;

    $self->__process_config_files( $self->__find_config_files() );

    $self->{disable} = {};

    __getopt( \%opt,
	qw{ verbose! },
	'disable=s'	=> sub {
	    my ( undef, $plugin ) = @_;
	    $plugin =~ m/ :: /smx
		or $plugin = join '::', PLUGIN_SEARCH_PATH, $plugin;
	    $self->{disable}{$plugin} = 1;
	    return;
	},
	'enable=s'	=> sub {
	    my ( undef, $plugin ) = @_;
	    $plugin =~ m/ :: /smx
		or $plugin = join '::', PLUGIN_SEARCH_PATH, $plugin;
	    $self->{disable}{$plugin} = 0;
	    return;
	},
	version	=> sub {
	    print <<"EOD";
@{[ __PACKAGE__ ]} $VERSION
    $COPYRIGHT
App::Ack $App::Ack::VERSION
    $App::Ack::COPYRIGHT
Perl $^V
EOD
	    exit;
	},
	'help|man' => sub {
	    @ARGV
		and defined $ARGV[0]
		and '' ne $ARGV[0]
		or Pod::Usage::pod2usage( { -verbose => 2 } );
	    if ( 'config' eq $ARGV[0] ) {
		my $count;
		foreach ( $self->__find_config_files() ) {
		    $count++;
		    print STDERR '    ',
			ref $_ ? "ACKXP_OPTIONS=$$_\n" : "$_\n";
		}
		$count
		    or print STDERR "    No configuration files found\n";
		exit 1;
	    } elsif ( 'plugins' eq $ARGV[0] ) {
		foreach ( $self->__plugins() ) {
		    s/ .* :: //smx;
		    print STDERR "    $_\n";
		}
		exit 1;
	    }
	    my $match = qr{ :: \Q$ARGV[0]\E \z }smx;
	    foreach ( $self->__plugins() ) {
		$_ =~ $match
		    or next;
		( my $file = "$_.pm" ) =~ s| :: |/|smxg;
		Pod::Usage::pod2usage( { -verbose => 2, -input => $INC{$file} } );
	    }
	    __warn( "No such plug-in as '$ARGV[0]'" );
	    exit 1;
	},
    );

    foreach my $p_rec ( $self->__marshal_plugins ) {
	my $plugin = $p_rec->{package};
	my $opt = __getopt_for_plugin( $plugin );
	$plugin->__process( $self, $opt );
    }

    my @inject = @{ $self->{inject} };

    if ( DEVELOPMENT &&
	__any { m/ \A -MApp::AckX::Preflight\b /smx } @inject
    ) {
	splice @inject, 0, 0, '-Mblib';
    }

    local $self->{verbose} = $opt{verbose};

    return $self->__execute(
	perl		=> @inject,
	qw{ -S ack }	=> @ARGV );
}

sub __execute {
    my ( $self, @arg ) = @_;

    if ( ref $self && $self->{verbose} ) {
	my @out;
	foreach my $in ( @arg ) {
	    if ( $in =~ m/ [\s'"\\] /smx ) {
		( my $temp = $in ) =~ s/ (?= ["\\] ) /\\/smxg;
		push @out, qq<"$temp">;
	    } else {
		push @out, $in;
	    }
	}
	print STDERR "\$ @out\n";
    }

    exec { $arg[0] } @arg
	or __die( "Failed to exec $arg[0]: $!" );
}

sub __find_config_files {
    my ( $self ) = @_;
    my $opt = __getopt( qw{ ackxprc=s ignore-ackxp-defaults! } );

    # I want to leave --env/--noenv in the command line for ack, but I
    # need to know its value.
    my $use_env = 1;
    __getopt( [ @ARGV ], 'env!' => \$use_env );

    my @files;

    # Files are processed in most-significant to least-significant
    # order, as shown below. Starred sources are disabled by --noenv

    # ACKXP_OPTIONS environment variable (*)
    $use_env
	and defined $ENV{ACKXP_OPTIONS}
	and '' ne $ENV{ACKXP_OPTIONS}
	and push @files, \$ENV{ACKXP_OPTIONS};
    # --ackxprc
    defined $opt->{ackxprc}
	and push @files, $opt->{ackxprc};

    if ( $use_env ) {
	# Project ackprc (walk directories current to root inclusive)(*)
	my $cwd = Cwd::getcwd();
	# TODO ack untaints this, but ...
	my @parts = File::Spec->splitdir( $cwd );
	while ( @parts ) {
	    my $path = $self->_file_from_parts( catdir => @parts )
		or next;
	    push @files, $path;
	    last;
	} continue {
	    pop @parts;
	}
	# User's home ackxprc (ACKXPRC or system-dependant location)(*)
	push @files, $self->_file_from_env( catfile => 'ACKXPRC' ) ||
	    $self->_file_from_parts( catdir => $self->home() );
	# Global ackxprc(*)
	push @files, $self->_file_from_parts(
	    catdir => $self->global(), [ 'ackxprc' ] );
    }
    # Built-in defaults (unless --ignore-ackxp-defaults)

    my %seen;
    return ( grep { ! $seen{__file_id( $_ )}++ } @files );
}

sub _file_from_env {	## no critic (RequireArgUnpacking)
    my ( $self, $method, @arg ) = @_;
    @arg
	or return;
    foreach ( @arg ) {
	defined $ENV{$_}
	    and '' ne $ENV{$_}
	    or return;
	$_ = $ENV{$_};
    }
    @_ = ( $self, $method, @arg );
    goto &_file_from_parts;
}

sub _file_from_parts {
    my ( undef, $method, @arg ) = @_;	# Invocant unused
    my $names = ARRAY_REF eq ref $arg[-1] ? pop @arg : [ qw{ .ackxprc
	_ackxprc } ];
    @arg
	or __die_hard( 'No file parts specified' );
    my $path = @arg > 1 ? File::Spec->$method( @arg ) : $arg[0];
    -d $path
	or return $path;
    my @f;
    foreach my $base ( @{ $names } ) {
	my $p = File::Spec->catfile( $path, $base );
	-r $p
	    and push @f, $p;
    }
    @f
	or return;
    local $" = ' and ';
    @f > 1
	and __die( "Both @f found; delete one" );
    return $f[0];
}

# Its own code so we can test it.
sub __marshal_plugins {
    my ( $self ) = @_;

    # Under the presumption that we are getting ready to actually run
    # the plugins, we clear the __inject() data. Obviously we can't do
    # this if we're being called as a static method for testing.
    if ( ref $self ) {
	$self->{inject}	= [];
    }

    # Go through all the plugins and index them by the options they
    # support.
    my %opt_to_plugin;
    my @plugin_without_opt;
    foreach my $plugin ( $self->__plugins() ) {
	my $p_rec = {
	    package	=> $plugin,
	};
	my $recorded;
	if ( my @opt_spec = $plugin->__options() ) {
	    $p_rec->{options} = \@opt_spec;
	    foreach ( @opt_spec ) {
		my $os = $_;			# Don't want alias
		$os =~ s/ \A -+ //smx;		# Optional leading dash
		$os =~ s/ ( [:=+!] ) .* //smx;	# Argument spec.
		my $negated = defined $1 && '!' eq $1;
		foreach my $o ( split qr{ [|] }smx, $os ) {
		    push @{ $opt_to_plugin{$o} ||= [] }, $p_rec;
		    if ( $negated ) {
			push @{ $opt_to_plugin{"no$o"} ||= [] }, $p_rec;
			push @{ $opt_to_plugin{"no-$o"} ||= [] }, $p_rec;
		    }
		    $recorded++;
		}
	    }
	}
	$recorded
	    or push @plugin_without_opt, $p_rec;
    }

    # Go through all the arguments, find the options, and record, in
    # order, the plug-in, if any, that handles each. Only the first use
    # of a plug-in is recorded.
    my @found_p_rec;
    my %num_found;
    foreach my $arg ( reverse @ARGV ) {
	$arg =~ m/ \A -+ ( [^=:]+ ) /smx
	    or next;
	foreach my $p_rec ( @{ $opt_to_plugin{$1} || [] } ) {
	    $num_found{$p_rec->{package}}++
		and next;
	    push @found_p_rec, $p_rec;
	}
    }

    %num_found = ();

    return (
	grep { ! $num_found{$_->{package}}++ }
	reverse( @found_p_rec ),
       	sort { $a->{package} cmp $b->{package} }
	    @plugin_without_opt,
	    map { @{ $_ } } values %opt_to_plugin,
    );
}

{

    my $mpo;

    sub __plugins {
	my ( $self ) = @_;
	$mpo ||= Module::Pluggable::Object->new(	# Oh, for state()
	    $self->__module_pluggable_object_new_args(),
	);
	my %disable;
	ref $self
	    and %disable = %{ $self->{disable} };
	my @rslt;
	foreach my $plugin ( $mpo->plugins() ) {
	    delete $disable{$plugin}
		and next;
	    $plugin->IN_SERVICE()
		or next;
	    push @rslt, $plugin;
	}
	if ( my @invalid = sort keys %disable ) {
	    @invalid > 1
		or __die( "Unknown plugin @invalid" );
	    local $" = ', ';
	    __die( "Unknown plugins @invalid" );
	}
	return @rslt;
    }
}

sub __module_pluggable_object_new_args {
    return (
	inner		=> 0,
	max_depth	=> PLUGIN_MAX_DEPTH,
	require		=> 1,
	search_path	=> PLUGIN_SEARCH_PATH,
    );
}

sub __process_config_files {
    my ( undef, @files ) = @_;			# Invocant unused
    foreach my $fn ( @files ) {
	my @args;
	if ( SCALAR_REF eq ref $fn ) {
	    @args = Text::ParseWords::shellwords( ${ $fn } );
	} else {
	    my $fh = __open_for_read( $fn );	# Dies on error.
	    while ( <$fh> ) {
		m/ \S /smx
		    and not m/ \A \s* [#] /smx
		    or next;
		chomp;
		push @args, $_;
	    }
	    close $fh;
	}
	splice @ARGV, 0, 0, @args;
    }
    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight - Extend App::Ack

=head1 SYNOPSIS

 use App::AckX::Preflight;

 App::AckX::Preflight->run();

=head1 DESCRIPTION

This Perl module extends L<App::Ack|App::Ack>, in a way. All it really
does is to let you mung the arguments passed to the F<ack> script.

All the interesting functionality is provided by a plugin system.

=head1 METHODS

This class supports the following methods. Methods whose names begin
with a double underscore C<'__'> are intended for the use of plugins
only.

=head2 new

 my $aaxp = App::AckX::Preflight->new();

This static method instantiates an C<App::AckX::Preflight> object. It
takes the following optional arguments as name/value pairs.

=over

=item global

This is the name of the directory in which the global configuration file
is stored. The directory must exist. The default is system-dependant,
and chosen to be compatible with L<App::Ack|App::Ack>:

=over

=item VMS: None. I will fix this if someone will tell me what it should
be.

=item Windows: C<Win32::CSIDL_COMMON_APPDATA()>.

=item anything else: C<'/etc'>.

=back

=item home

This is the name of the directory in which the user's configuration file
is stored. The directory must exist. The default is system-dependant,
and chosen to be compatible with L<App::Ack|App::Ack>:

=over

=item VMS: C<$ENV{'SYS$LOGIN'}>.

=item Windows: C<Win32::CSIDL_APPDATA()>.

=item anything else: C<$ENV{HOME}>.

=back

=back

If C<new()> is called as a normal method it clones its invocant,
applying the arguments (if any) after the clone.

=head2 global

 say App::Ack::Preflight->global();
 say $aaxp->global();

If called on an object, this method returns the value of the C<{global}>
attribute, whether explicit or defaulted. If called statically, it
returns the default value of the C<{global}> attribute.

=head2 home

 say App::Ack::Preflight->home();
 say $aaxp->home();

If called on an object, this method returns the value of the C<{home}>
attribute, whether explicit or defaulted. If called statically, it
returns the default value of the C<{home}> attribute.

=head2 __inject

 $self->__inject( qw{ -MFoo::Bar } )

A plug-in would call this method to inject options into the F<perl>
command used to C<exec()> F<ack>.

B<Note> that if B<any> C<@INC> entry matches C</\bblib\b/>, B<and> any
injected item matches C</\A-MApp::AckX::Preflight\b/>, C<-Mblib> will be
injected before the first such item.

=head2 run

 App::Ack::Preflight->run();
 $aaxp->run();

This method first handles C<App::AckX::Preflight>-specific options,
which are removed from the command passed to F<ack> unless otherwise
documented:

=over

=item C<--disable>

 --disable=plugin_name

This option disables the named plugin. The name is either the complete
class name or the name without the C<'App::AckX::Preflight::Plugin::'>
prefix.

An exception occurs if the name of an unknown plugin is given.

=item C<--enable>

 --enable=plugin_name

This option enables the named plug-in. That is, it undoes a previous
C<--disable>; specifying this will not make an unavailable plug-in
available. The name is either the complete class name or the name
without the C<'App::AckX::Preflight::Plugin::'> prefix.

An exception occurs if the name of an unknown plugin is given.

=item C<--env>

This Boolean option requests the use of the environment (i.e.
environment variables, configuration files) to configure
C<App::AckX::Preflight>. This option is passed on to F<ack> itself.

The default is C<--env>, but this can be negated with C<--noenv>.

=item C<--help>

This options causes the POD of the top-level script (as determined by
C<$0>) to be displayed. The script then exits.

This option can also be given one of the following arguments:

=over

=item C<'config'>

This argument causes the names of any configuration files used to be
displayed.

=item C<'plugins'>

This argument causes the names of any available plugins to be displayed.

=item plugin name

If this argument is an item from the plugins list, the POD for that
plugin will be displayed.

=back

All other arguments to C<--help> are invalid and result in an error.

=item C<--man>

This is a synonym for C<--help>, and takes the same optional arguments.

=item C<--verbose>

This causes C<App::AckX::Preflight> to write certain information to
standard error. The exact nature of this information is undocumented,
and subject to change without notice.

=item C<--version>

This option causes the versions of C<App::AckX::Preflight>,
L<App::Ack|App::Ack>, and Perl to be displayed. The script then exits.

=back

This method then reads all the configuration files, calls the plugins,
and then C<exec()>s F<ack>, passing it C<@ARGV> as it stands after all
the plugins have finished with it.

Plug-ins that have an L<__options()|/__options> method are called in the
order the specified options appear on the command line. If a plug-in's
L<__options()|/__options> method returns more than one option, or if an
option is specified more than once, the last one seen determines the
order. If more than one plug-in specifies the same option, they are
processed in ASCIIbetical order.

Plug-ins whose options do not appear in the actual command, or that do
not implement an L<__options()|/__options> method are called last, in
ASCIIbetical order.

This method B<does not return.>

=head1 PLUGINS

Plugins B<must> be named
C<App::AckX::Preflight::Plugin::something_or_other>. They B<may> be
subclassed from C<App::AckX::Preflight::Plugin>, but need not as long as
they conform to its interface.

=head1 CONFIGURATION

The configuration system mirrors that of L<App::Ack|App::Ack> itself, as
nearly as I can manage. The only known difference is support for VMS.
Any other differences will be resolved in favor of C<App::Ack|App::Ack>.

Like L<App::Ack|App::Ack>'s configuration system,
C<App::AckX::Preflight>'s configuration is simply a list of default
command line options to be prepended to the command line. Options
specific to C<App::AckX::Preflight> will be removed before the command
line is presented to F<ack>.

The Configuration comes from the following sources, in order from
most-general to most-specific. If an option is specified more than once,
the most-specific one rules. It is probably a 'feature' (in the sense of
'documented bug') that C<App::AckX::Preflight> configuration data trumps
L<App::Ack|App::Ack> configuration data.

=over

=item Global configuration file.

This optional file is named F<ackxprc>, and lives in the directory
reported by the L<global()|/global> method.

This configuration file is ignored if C<--noenv> is specified.

=item User-specific configuration file.

If environment variable C<ACKXPRC> exists and is non-empty, it points to
the user-specific configuration file, which must exist.

Otherwise this optional file is whichever of F<.ackxprc> or F<_ackxprc>
actually exists. It is an error if both exist.

This configuration file is ignored if C<--noenv> is specified.

=item Project-specific configuration file.

This optional file is the first of F<.ackxprc> or F<_ackxprc> found by
walking up the directory tree from the current directory. It is an error
if both files are found in the same directory.

This configuration file is ignored if C<--noenv> is specified.

=item Configuration file specified by C<--ackxprc>

If this option is specified, the file must exist.

=item The contents of environment variable C<ACKXP_OPTIONS>

This optional environment variable will be parsed by
C<Text::Parsewords::shellwords()>.

This environment variable is ignored if C<--noenv> is specified.

=back

=head1 SEE ALSO

L<App::Ack|App::Ack>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
