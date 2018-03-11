package App::AckX::Preflight;

use 5.008008;

use strict;
use warnings;

use App::Ack();
use Carp;
use Cwd ();
use File::Basename ();
use File::Spec;
use Getopt::Long 2.33;
use Module::Pluggable::Object 5.2;
use Text::ParseWords ();

our $VERSION = '0.000_001';

use constant ARRAY_REF	=> ref [];
use constant SCALAR_REF	=> ref \0;

use constant IS_VMS	=> 'VMS' eq $^O;
use constant IS_WINDOWS	=> { map { $_ => 1 } qw{ dos MSWin32 } }->{$^O};

BEGIN {
    IS_WINDOWS
	and require Win32;
}

use constant FILE_ID_IS_INODE	=> ! { map { $_ => 1 }
    qw{ dos MSWin32 VMS } }->{$^O};

use constant SEARCH_PATH	=> join '::', __PACKAGE__, 'Plugin';
use constant MAX_DEPTH		=> do {
    my @parts = split qr{ :: }smx, SEARCH_PATH;
    1 + @parts;
};

{
    my %default = (
	global	=> IS_VMS ? undef :	# TODO what, exactly?
	    IS_WINDOWS ? Win32::CSIDL_COMMON_APPDATA() :
	    '/etc',
	home	=> IS_VMS ? $ENV{'SYS$LOGIN'} :
	    IS_WINDOWS ? Win32::CSIDL_APPDATA() :
	    $ENV{HOME},
    );

    sub new {
	my ( $class, %arg ) = @_;

	ref $class
	    and %arg = ( %{ $class }, %arg );

	foreach ( keys %arg ) {
	    exists $default{$_}
		or croak "Argument '$_' not supported";
	}

	foreach ( keys %default ) {
	    defined $arg{$_}
		or $arg{$_} = $default{$_};
	}

	foreach ( qw{ global home } ) {
	    -d $arg{$_}
		or croak "Argument '$_' must be a directory";
	}

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

sub die : method {	## no critic (ProhibitBuiltinHomonyms,RequireFinalReturn)
    my ( undef, @arg ) = @_;
    App::Ack::die( @arg );
}

{
    my $psr = Getopt::Long::Parser->new();
    $psr->configure( qw{
	no_auto_version no_ignore_case no_auto_abbrev pass_through
	},
    );

    sub getopt {
	my ( $self, @opt_spec ) = @_;
	my %opt;
	$psr->getoptions( \%opt, @opt_spec )
	    or $self->die( 'Invalid option' );	# TODO something better
	return \%opt;
    }
}

sub run {
    my ( $self ) = @_;
    $self->getopt(
	version	=> sub {
	    print <<"EOD";
@{[ __PACKAGE__ ]} $VERSION
App::Ack $App::Ack::VERSION
Perl $^V
EOD
	exit;
	},
    );

    $self->__process_files( $self->__find_files() );

    foreach my $p_rec ( $self->__marshal_plugins ) {
	my $code = $p_rec->{package}->can( '__process' )
	    or $p_rec->{package}->__process();	# Just to get the error.
	my $opt = $p_rec->{options} ?
	    $self->getopt( @{ $p_rec->{options} } ) :
	    {};
	$code->( $self, $opt );
    }

    return $self->__execute( ack => @ARGV );
}

sub __execute {
    my ( $self, @arg ) = @_;

    exec { $arg[0] } @arg
	or $self->die( "Failed to exec $arg[0]: $!" );
}

sub __find_files {
    my ( $self ) = @_;
    my $opt = $self->getopt( qw{ ackxprc=s ignore-ackxp-defaults! } );

    my $use_env = ! grep { m/ \A --?  noenv \z /smx } @ARGV;

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
    return ( grep { ! $seen{_file_id( $_ )}++ } @files );
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
    my ( $self, $method, @arg ) = @_;
    my $names = ARRAY_REF eq ref $arg[-1] ? pop @arg : [ qw{ .ackxprc
	_ackxprc } ];
    @arg
	or $self->die( "No file parts specified" );	# TODO Confess?
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
	and $self->die( "Both @f found; delete one" );
    return $f[0];
}

sub _file_id {
    my ( $path ) = @_;
    return FILE_ID_IS_INODE ?
	join( ':', ( stat $path )[ 0, 1 ] ) :
	Cwd::abs_path( $path );
}

# Its own code so we can test it.
sub __marshal_plugins {
    my ( $self ) = @_;

    # Go through all the plugins and index them by the options they
    # support.
    my %opt_to_plugin;
    my @plugin_without_opt;
    foreach my $plugin ( $self->__plugins() ) {
	my $p_rec = {
	    package	=> $plugin,
	};
	my $recorded;
	if ( $plugin->can( '__options' ) and my @opt_spec =
	    $plugin->__options() ) {
	    $p_rec->{options} = \@opt_spec;
	    foreach ( @opt_spec ) {
		my $os = $_;			# Don't want alias
		$os =~ s/ \A -+ //smx;		# Optional leading dash
		$os =~ s/ ( [:=+!] ) .* //smx;	# Argument spec.
		my $negated = '!' eq $1;
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
	$mpo ||= Module::Pluggable::Object->new(	# Oh, for state()
	    filename	=> __FILE__,
	    inner		=> 0,
	    max_depth	=> MAX_DEPTH,
	    package		=> __PACKAGE__,
	    require		=> 1,
	    search_path	=> SEARCH_PATH,
	);
	return $mpo->plugins();
    }
}

sub __process_files {
    my ( $self, @files ) = @_;
    foreach my $fn ( @files ) {
	my @args;
	if ( SCALAR_REF eq ref $fn ) {
	    @args = Text::ParseWords::shellwords( ${ $fn } );
	} else {
	    open my $fh, '<:encoding(utf-8)', $fn	## no critic (RequireBriefOpen)
		or $self->die( "Failed to open $fn: $!" );
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

This class supports the following public methods:

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

=head2 die

 App::Ack::Preflight->die( 'Goodbye, cruel world!' );
 $aaxp->die( 'Ditto.' );

This method is simply a wrapper for C<App::Ack::die()>.

=head2 getopt

 my $opt = App::AckX::Preflight->getopt(
     qw{ foo! bar=s } );
 my $opt2 = $aaxp->getopt( qw{ foo! bar=s } );

This method simply calls C<Getopt::Long::GetOptions>, with the package
configured appropriately for our use. Any arguments actually processed
will be removed from C<@ARGV>. The return is a reference to the options
hash.

The actual configuration used is

 no_auto_version no_ignore_case no_auto_abbrev pass_through

which is what L<App::Ack|App::Ack> uses.

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

=head2 run

 App::Ack::Preflight->run();
 $aaxp->run();

This method reads all the configuration files, calls the plugins,
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
C<App::AckX::Preflight::Plugin::something_or_other>. They B<must not> be
subclassed from C<App::AckX::Preflight::Plugin>, because that does not
exist.

Plugins B<may> implement the following static methods:

=head2 __options

This static method returns L<Getopt::Long|Getopt::Long> option
specifiers for options associated with this plug-in. This method is
optional, but if it exists, and actually returns at least one option
specifier, two things happen:

=over

=item * The L<run()|/run> method will call L<getopt()|/getopt> on your
behalf, passing you the results.

=item * If any of the specified options actually appears in the command
line, this plug-in will be called before plug-ins that do not implement
L<__options()|/__options>, and before those whose options do not appear.

=back

Plug-ins that do not implement this are free to do options processing
when they are called, but their processing order is as through they had
no options.

Boiler plate for this method looks something like

 sub __options {
     return( qw{ foo=s bar|baz! } );
 }

=head2 __process

This static method is called as though it was invoked by this class,
even though it is not a member of this class. It returns nothing.  It is
allowed, and in fact expected, to modify C<@ARGV> in the course of its
duties.

This method B<must> be implemented. Boiler plate for this method would
look something like

 sub __process {
     my ( $preflight, $opt ) = @_;
     ...
 }

if the plug-in implements L<__options()|/__options>, or

 sub __process {
     my ( $preflight ) = @_;
     my $opt = $preflight->getopt( ... );
     ...
 }

if it does not. If the plug-in has no options, use the latter form but
omit the call to C<getopt()>.

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
