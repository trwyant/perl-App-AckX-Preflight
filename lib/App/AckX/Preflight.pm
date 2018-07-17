package App::AckX::Preflight;

use 5.008008;

use strict;
use warnings;

use App::Ack ();
use App::AckX::Preflight::Util ();
use Cwd ();
use File::Spec;
use List::Util 1.45 ();	# For uniqstr, which this module does not use
use Pod::Usage ();
use Text::ParseWords ();

our $VERSION;
our $COPYRIGHT;

use constant DEVELOPMENT => grep { m{ \b blib \b }smx } @INC;

use constant IS_VMS	=> 'VMS' eq $^O;
use constant IS_WINDOWS	=> { map { $_ => 1 } qw{ dos MSWin32 } }->{$^O};

BEGIN {

    App::AckX::Preflight::Util->import( ':all' );

    $VERSION = '0.000_019';
    $COPYRIGHT = 'Copyright (C) 2018 by Thomas R. Wyant, III';

    IS_WINDOWS
	and require Win32;
}

use constant PLUGIN_SEARCH_PATH	=> join '::', __PACKAGE__, 'Plugin';
use constant PLUGIN_MATCH	=> qr< \A @{[ PLUGIN_SEARCH_PATH ]} :: >smx;

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

    $self->__process_config_files(
	my @config_files = $self->__find_config_files() );

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
	'help|man:s' => sub {
	    my ( undef, $val ) = @_;
	    if ( '' eq $val ) {
		Pod::Usage::pod2usage( { -verbose => 2 } );
	    } elsif ( 'config' eq $val ) {
		foreach ( @config_files ) {
		    print STDERR '    ',
			ref $_ ? "ACKXP_OPTIONS=$$_\n" : "$_\n";
		}
		@config_files
		    or print STDERR "    No configuration files found\n";
		exit 1;
	    } elsif ( 'plugins' eq $val ) {
		foreach ( $self->__plugins() ) {
		    s/ .* :: //smx;
		    print STDERR "    $_\n";
		}
		exit 1;
	    }
	    my $match = qr{ :: \Q$val\E \z }smx;
	    foreach ( $self->__plugins() ) {
		$_ =~ $match
		    or next;
		( my $file = "$_.pm" ) =~ s| :: |/|smxg;
		Pod::Usage::pod2usage( { -verbose => 2, -input => $INC{$file} } );
	    }
	    __warn( "No such plug-in as '$val'" );
	    exit 1;
	},
    );

    foreach my $p_rec ( $self->__marshal_plugins ) {
	my $plugin = $p_rec->{package};
	my $opt = __getopt_for_plugin( $plugin );
	$plugin->__process( $self, $opt );
    }

    local $self->{verbose} = $opt{verbose};

    if ( IS_SINGLE_FILE ) {
	$self->_trace( ack => @ARGV );
	return;
    } else {

	my @inject = @{ $self->{inject} };

	if ( DEVELOPMENT &&
	    List::Util::any { m/ \A -MApp::AckX::Preflight\b /smx } @inject
	) {
	    splice @inject, 0, 0, '-Mblib';
	}

	return $self->__execute(
	    perl		=> @inject,
	    qw{ -S ack }	=> @ARGV );
    }
}

sub __execute {
    my ( $self, @arg ) = @_;

    $self->_trace();

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
    my %loaded;

    sub __plugins {
	my ( $self ) = @_;

	my %disable;
	ref $self
	    and %disable = %{ $self->{disable} };
	my @rslt;
#	foreach my $plugin ( $mpo->plugins() ) {
	foreach my $plugin ( @CARP_NOT ) {
	    $plugin =~ PLUGIN_MATCH
		or next;
	    delete $disable{$plugin}
		and next;
	    IS_SINGLE_FILE
		or ( $loaded{$plugin} ||= eval "require $plugin; 1" )
		or next;
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

sub _trace {
    my ( $self, @arg ) = @_;
    ref $self
	and $self->{verbose}
	or return;
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
documented.

For the convenience of the user, these are documented in
L<ackxp|/ackxp>. For the convenience of the author, that documentation
is not repeated here.

This method then reads all the configuration files, calls the plugins,
and then C<exec()>s F<ack>, passing it C<@ARGV> as it stands after all
the plugins have finished with it. See the
L<CONFIGURATION|ackxp/CONFIGURATION> documentation in L<ackxp|ackxo> for
the details.

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
