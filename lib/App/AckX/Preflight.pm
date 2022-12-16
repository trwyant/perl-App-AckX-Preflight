package App::AckX::Preflight;

use 5.010001;

use strict;
use warnings;

use App::Ack ();
use App::AckX::Preflight::Util qw{ :all };
use Cwd ();
use File::Spec;
use IPC::Cmd ();	# for can_run
use List::Util 1.45 ();	# For uniqstr, which this module does not use
use Pod::Usage ();
use Text::ParseWords ();

our $VERSION = '0.000_043';
our $COPYRIGHT = 'Copyright (C) 2018-2022 by Thomas R. Wyant, III';

use constant DEVELOPMENT => grep { m{ \b blib \b }smx } @INC;

use constant IS_VMS	=> 'VMS' eq $^O;
use constant IS_WINDOWS	=> { map { $_ => 1 } qw{ dos MSWin32 } }->{$^O};

use if IS_WINDOWS, 'Win32';

use constant PLUGIN_SEARCH_PATH	=> join '::', __PACKAGE__, 'Plugin';
use constant PLUGIN_MATCH	=> qr< \A @{[ PLUGIN_SEARCH_PATH ]} :: >smx;

{
    my %default = (
	exec	=> 0,
	global	=> IS_VMS ? undef :	# TODO what, exactly?
	    IS_WINDOWS ? Win32::CSIDL_COMMON_APPDATA() :
	    '/etc',
	home	=> IS_VMS ? $ENV{'SYS$LOGIN'} :
	    IS_WINDOWS ? Win32::CSIDL_APPDATA() :
	    $ENV{HOME},
	output	=> DEFAULT_OUTPUT,
	verbose	=> 0,
    );

    foreach my $dir ( qw{ global home } ) {
	defined $default{$dir}
	    or next;
	-d $default{$dir}
	    or $default{$dir} = undef;
    }

    sub new {
	my ( $class, %arg ) = @_;

	ref $class
	    and %arg = ( %{ $class }, %arg );

	foreach ( keys %arg ) {
	    exists $default{$_}
		or __die( "Argument '$_' not supported" );
	}

	foreach ( qw{ global home } ) {
	    defined $arg{$_}
		or next;
	    -d $arg{$_}
		or __die( "Argument '$_' must be a directory" );
	}

	foreach ( keys %default ) {
	    $arg{$_} //= $default{$_};
	}

	$arg{disable}	= {};

	return bless \%arg, ref $class || $class;
    }

    sub exec : method {	## no critic (ProhibitBuiltinHomonyms)
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{exec};
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

    sub output {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{output};
    }

    sub verbose {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{verbose};
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

    my %opt = (
	default	=> {},
    );

    $self->__process_config_files(
	my @config_files = $self->__find_config_files() );

    $self->{disable} = {};

    my @argv = @ARGV;

    __getopt( \%opt,
	qw{ default=s% dry_run|dry-run! exec! output=s verbose! },
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
		    print STDERR '    ', $_->name(), "\n";
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
	    my $match = lc $val;
	    foreach ( $self->__plugins() ) {
		$_->__name() eq $match
		    or next;
		( my $file = "$_.pm" ) =~ s| :: |/|smxg;
		Pod::Usage::pod2usage( { -verbose => 2, -input => $INC{$file} } );
	    }
	    __warn( "No such plug-in as '$val'" );
	    exit 1;
	},
    );

    $opt{verbose} //= $opt{dry_run};

    $opt{verbose}
	and warn scalar _shell_quote( '$', $0, @argv ), "\n";

    use App::AckX::Preflight::Util qw{ __interpret_plugins };

    $self->{inject} = [];

    my @plugins = __interpret_plugins( $opt{default}, $self->__plugins() );

    foreach my $p ( @plugins ) {
	$p->{class}->__wants_to_run( $p->{opt} )
	    or next;
	$p->{class}->__process( $self, $p->{opt} );
    }

    local $self->{dry_run} = $opt{dry_run};
    local $self->{exec}    = defined $opt{exec} ?
	$opt{exec} : $self->{exec};
    local $self->{output}  = defined $opt{output} ?
	$opt{output} : $self->{output};
    local $self->{verbose} = defined $opt{verbose} ?
	$opt{verbose} : $self->{verbose};

    my @inject = @{ $self->{inject} };

    if ( DEVELOPMENT &&
	List::Util::any { m/ \A -MApp::AckX::Preflight\b /smx } @inject
    ) {
	splice @inject, 0, 0, '-Mblib';
    }

    my $ack = IPC::Cmd::can_run( 'ack' )
	or __die( q<Can not find 'ack' executable> );

    my @arg = (
	$^X		=> @inject,
	$ack,
	@ARGV,
    );

    return $self->__execute( @arg );
}

sub __execute {
    my ( $self, @arg ) = @_;

    $self->_trace( @arg );

    ref $self
	and $self->{dry_run}
	and return;

    # Redirect STDOUT to a file if needed. We make no direct use of the
    # returned object, but hold it because its destructor undoes the
    # redirect on scope exit.
    # NOTE that we rely on the fact that destructors are NOT run when an
    # exec() is done.
    my $redirect = App::AckX::Preflight::_Redirect::Stdout->new(
	$self->output() );

    if ( $self->exec() ) {

	exec { $arg[0] } @arg
	    or __die( "Failed to exec $arg[0]: $!" );

    } else {

	system { $arg[0] } @arg;
	$? == 0
	    or $? == 0x100
	    or __die( __interpret_exit_code( $? ) );
	return $? >> 8;
    }

    return;
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
	and push @files, App::AckX::Preflight::_Config::Env->new(
	    name	=> 'ACKXP_OPTIONS' );;

    # --ackxprc
    defined $opt->{ackxprc}
	and push @files, App::AckX::Preflight::_Config::File->new(
	    name	=> $opt->{ackxprc} );

    if ( $use_env ) {
	# Project ackprc (walk directories current to root inclusive)(*)
	my $cwd = Cwd::getcwd();
	# TODO ack untaints this, but ...
	my @parts = File::Spec->splitdir( $cwd );
	while ( @parts ) {
	    my $cfg = $self->_file_from_parts( catdir => @parts )
		or next;
	    push @files, $cfg;
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
    return ( grep { ! $seen{ $_->id() }++ } @files );
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
    defined $arg[0]
	or return;
    my $path = File::Spec->$method( @arg );
    -d $path
	or return App::AckX::Preflight::_Config::File->new( name => $path );
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
    return App::AckX::Preflight::_Config::File->new( name => $f[0] );
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
	    ( $loaded{$plugin} ||= eval "require $plugin; 1" )
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
    foreach my $cfg ( @files ) {
	my @args;
	$cfg->open();
	local $_ = undef;
	while ( defined ( $_ = $cfg->read() ) ) {
	    m/ \S /smx
		and not m/ \A \s* [#] /smx
		or next;
	    chomp;
	    push @args, $_;
	}
	$cfg->close();
	splice @ARGV, 0, 0, @args;
    }
    return;
}

sub _shell_quote {
    my @args = @_;
    defined wantarray
	or __die_hard( '_shell_quote() called in void context' );
    foreach ( @args ) {
	m/ ["'\s] /smx
	    or next;
	s/ (?= ['\\] ) /\\/smxg;
	$_ = "\$'$_'";
    }
    return wantarray ? @args : "@args";
}

sub _trace {
    my ( $self, @arg ) = @_;
    $self->verbose()
	or return;
    warn scalar _shell_quote( '$', @arg ), "\n";
    return;
}

package App::AckX::Preflight::_Config;	## no critic (ProhibitMultiplePackages)

use App::AckX::Preflight::Util qw{ :croak @CARP_NOT };

sub new {
    my ( $class, %arg ) = @_;
    defined $arg{name}
	and '' ne $arg{name}
	or __die_hard( 'No name specified' );
    return bless \%arg, ref $class || $class;
}

sub name {
    my ( $self ) = @_;
    return $self->{name};
}

package App::AckX::Preflight::_Config::File;	## no critic (ProhibitMultiplePackages)

use parent qw{ -norequire App::AckX::Preflight::_Config };

use App::AckX::Preflight::Util qw{ :croak __file_id @CARP_NOT };

sub close : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    $self->{fh}
	and close delete $self->{fh};
    return $self;
}

sub id {
    my ( $self ) = @_;
    return join ':', file => __file_id( $self->name() );
}

sub open : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    $self->close();
    open $self->{fh}, '<:encoding(utf-8)', $self->name()
	or __die( sprintf 'Failed to open %s: %s', $self->name(), $! );
    return $self;
}

sub read : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    my $fh = $self->{fh} ||= $self->open()
	or __die_hard( 'open() not called' );
    return <$fh>;
}

package App::AckX::Preflight::_Config::Env;	## no critic (ProhibitMultiplePackages)

use parent qw{ -norequire App::AckX::Preflight::_Config };

use App::AckX::Preflight::Util qw{ :croak @CARP_NOT };
use Text::ParseWords ();

sub close : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    delete $self->{data};
    return $self;
}

sub id {
    my ( $self ) = @_;
    return join ':', env => $self->name();
}

sub read : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    my $data = $self->{data}
	or __die_hard( 'open() not called' );
    return shift @{ $data };
}

sub open : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    my $name = $self->name();
    defined $ENV{$name}
	or __die( sprintf 'Environment variable %s not defined', $name );
    $self->{data} = [ Text::ParseWords::shellwords( $ENV{$name} ) ];
    return $self;
}

package App::AckX::Preflight::_Redirect::Stdout;	## no critic (ProhibitMultiplePackages)

use App::AckX::Preflight::Util qw{ DEFAULT_OUTPUT __die };

sub new {
    my ( $class, $to ) = @_;

    # No need for cleanup if we do not actually redirect.
    defined $to
	and $to ne DEFAULT_OUTPUT
	or return undef;	## no critic (ProhibitExplicitReturnUndef)

    open my $from, '>&', \*STDOUT	## no critic (RequireBriefOpen)
	or __die( "Failed to dup STDOUT: $!" );
    close STDOUT;
    open STDOUT, '>', $to
	or __die( "Failed to re-open STDOUT to $to: $!" );

    return bless \$from, $class;
}

sub DESTROY {
    my ( $self ) = @_;
    close STDOUT;
    open STDOUT, '>&', ${ $self }
	or __die( "Failed to restore STDOUT: $!" );
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

=item exec

If this Boolean argument is true, F<ack> is run by C<exec()>, meaning
that the caller of L<run()|/run> never gets control back. If false,
F<ack> is run by either L<IPC::Cmd::run()|IPC::Cmd> if L<run()|/run>
finds the C<--output> option, or C<system()> if not.

The default is C<0>, i.e. false.

=item global

This is the name of the directory in which the global configuration file
is stored. The directory must exist. The default is system-dependant,
and chosen to be compatible with L<App::Ack|App::Ack>:

=over

=item VMS: None. I will fix this if someone will tell me what it should be.

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

=item output

This is the default output file name. The default is C<'-'>, which
specifies standard output.

=item verbose

This Boolean is the default verbosity setting. The default is C<0> (i.e.
false) which means non-verbose.

=back

If C<new()> is called as a normal method it clones its invocant,
applying the arguments (if any) after the clone.

=head2 exec

 say App::Ack::Preflight->global();
 say $aaxp->global();

If called on an object, this method returns the value of the C<{exec}>
attribute, whether explicit or defaulted. If called statically, it
returns the default value of the C<{exec}> attribute.

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

=head2 output

 say App::Ack::Preflight->output();
 say $aaxp->output();

If called on an object, this method returns the value of the C<{output}>
attribute, whether explicit or defaulted. If called statically, it
returns the default value of the C<{output}> attribute.

B<Note> that the L<run()|/run> method may override this if C<--output>
was specified on the command line.

=head2 verbose

 say App::Ack::Preflight->verbose();
 say $aaxp->verbose();

If called on an object, this method returns the value of the
C<{verbose}> attribute, whether explicit or defaulted. If called
statically, it returns the default value of the C<{verbose}> attribute.

B<Note> that the L<run()|/run> method may override this if C<--verbose>
or C<--no-verbose> was specified on the command line.

=head2 run

 App::Ack::Preflight->run();
 $aaxp->run();

This method first handles C<App::AckX::Preflight>-specific options,
which are removed from the command passed to F<ack> unless otherwise
documented.

For the convenience of the user, these are documented in
L<ackxp|ackxp>. For the convenience of the author, that documentation
is not repeated here.

This method then reads all the configuration files, calls the plugins,
and then C<exec()>s F<ack>, passing it C<@ARGV> as it stands after all
the plugins have finished with it. See the
L<CONFIGURATION|ackxp/CONFIGURATION> documentation in L<ackxp|ackxp> for
the details.

Plug-ins that have an
L<__options()|App::AckX::Preflight::Plugin/__options> method are called
in the order the specified options appear on the command line. If a
plug-in's L<__options()|App::AckX::Preflight::Plugin/__options> method
returns more than one option, or if an option is specified more than
once, the last one seen determines the order. If more than one plug-in
specifies the same option, they are processed in ASCIIbetical order.

Plug-ins whose options do not appear in the actual command, or that do
not implement an L<__options()|App::AckX::Preflight::Plugin/__options>
method are called last, in ASCIIbetical order.

If the C<exec> attribute is true, this method runs F<ack> via
C<exec()>, and B<does not return.>

If the C<exec> attribute is false (the default), this method runs F<ack>
via C<system()>. In this case, it dies if F<ack> signals, or exits with
any status but C<0> or C<1>. If it does not die, it returns the exit
status.

=head1 PLUGINS

Plugins B<must> be named
C<App::AckX::Preflight::Plugin::something_or_other>. They B<may> be
subclassed from C<App::AckX::Preflight::Plugin>, but need not as long as
they conform to its interface.

=head1 SEE ALSO

L<App::Ack|App::Ack>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
