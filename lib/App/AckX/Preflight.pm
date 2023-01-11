package App::AckX::Preflight;

use 5.010001;

use strict;
use warnings;

use App::Ack ();
use App::AckX::Preflight::Util qw{ :all };
use Cwd ();
use Encode ();
use File::Spec;
use IPC::Cmd ();	# for can_run
use List::Util 1.45 ();	# For uniqstr, which this module does not use
use Pod::Usage ();
use Text::Abbrev ();
use Text::ParseWords ();

our $VERSION = '0.000_046';
our $COPYRIGHT = 'Copyright (C) 2018-2023 by Thomas R. Wyant, III';

use constant DEVELOPMENT => grep { m{ \b blib \b }smx } @INC;

use constant DISPATCH_EXEC	=> 'exec';
use constant DISPATCH_NONE	=> 'none';
use constant DISPATCH_SYSTEM	=> 'system';

use if IS_WINDOWS, 'Win32';

use constant PLUGIN_SEARCH_PATH	=> join '::', __PACKAGE__, 'Plugin';
use constant PLUGIN_MATCH	=> qr< \A @{[ PLUGIN_SEARCH_PATH ]} :: >smx;

{
    my %default = (
	dispatch => DISPATCH_SYSTEM,
	global	=> IS_VMS ? undef :	# TODO what, exactly?
	    IS_WINDOWS ? Win32::CSIDL_COMMON_APPDATA() :
	    '/etc',
	home	=> IS_VMS ? $ENV{'SYS$LOGIN'} :
	    IS_WINDOWS ? Win32::CSIDL_APPDATA() :
	    $ENV{HOME},
	output	=> DEFAULT_OUTPUT,
	output_encoding	=> undef,
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

	if ( IS_WINDOWS && $arg{dispatch} eq DISPATCH_EXEC ) {
	    $arg{dispatch} = DISPATCH_SYSTEM;
	    __warn( '--dispatch=exec ignored under Windows' );
	}

	$arg{output_encoding} = __check_encoding( $arg{output_encoding} );

	$arg{disable}	= {};

	return bless \%arg, ref $class || $class;
    }

    sub dispatch {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{dispatch};
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

    sub output_encoding {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{output_encoding};
    }

    sub verbose {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{verbose};
    }
}

sub __file_monkey {
    my ( $self, $class, $config ) = @_;
    defined $class
	and $config
	and push @{ $self->{file_monkey} }, [ $class => $config ];
    # Coded this way because we want to return nothing in list context
    $self->{file_monkey}
	or return;
    return $self->{file_monkey};
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
	qw{ default=s% dry_run|dry-run!
	output_encoding|output-encoding=s verbose! },
	'dispatch=s'	=> sub {
	    my ( $name, $value ) = @_;
	    state $expand = Text::Abbrev::abbrev(
		DISPATCH_EXEC,
		DISPATCH_NONE,
		DISPATCH_SYSTEM,
	    );
	    $self->{dispatch} = $expand->{$value}
		or __die( "Invalid value '$value' for --$name" );
	    return;
	},
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
	'OUT=s'	=> sub {
	    my ( undef, $value ) = @_;
	    $opt{output} = $value;
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

    $self->{file_monkey} = [];

    my @plugins = __interpret_plugins( $opt{default}, $self->__plugins() );

    foreach my $p ( @plugins ) {
	$p->{class}->__wants_to_run( $p->{opt} )
	    or next;
	$p->{class}->__process( $self, $p->{opt} );
    }

    local $self->{dispatch} = $opt{dispatch} // $self->{dispatch};
    local $self->{dry_run} = $opt{dry_run};
    local $self->{output}  = $opt{output} // $self->{output};
    local $self->{output_encoding} = __check_encoding(
	$opt{output_encoding} ) // $self->{output_encoding};
    local $self->{verbose} = $opt{verbose} // $self->{verbose};

    my @rslt = $self->__execute( @ARGV );

    return @rslt;

}

sub _build_ack_command {
    my ( $self, @arg ) = @_;

    my @inject;

    if ( $self->{file_monkey} && @{ $self->{file_monkey} } ) {
	my $string = __json_encode( $self->{file_monkey} );
	splice @inject, 0, 0, "-MApp::AckX::Preflight::FileMonkey=$string";
	DEVELOPMENT
	    and splice @inject, 0, 0, '-Mblib';
    }

    unless ( $self->{dispatch_literal} ) {
	my $ack = IPC::Cmd::can_run( 'ack' )
	    or __die( q<Can not find 'ack' executable> );
	push @inject, $ack;
    }

    return(
	$^X		=> @inject,
	@arg,
    );
}

sub __execute {
    my ( $self, @arg ) = @_;

    my %file_monkey_config = (
	output		=> $self->output(),
	output_encoding	=> $self->output_encoding(),
	verbose		=> $self->verbose(),
    );
    splice @{ $self->{file_monkey} }, 0, 0, [
	MODULE_FILE_MONKEY, \%file_monkey_config ];

    $self->_trace( @arg );

    $self->{dry_run}
	and return;

    state $dispatch = {
	DISPATCH_EXEC,	sub {
	    my ( $self, @arg ) = @_;
	    @arg = $self->_build_ack_command( @arg );
	    exec { $arg[0] } @arg
		or __die( "Failed to exec $arg[0]: $!" );
	    return;
	},
	DISPATCH_NONE,	sub {
	    my ( $self, @arg ) = @_;
	    my %rslt;
	    if ( $self->{file_monkey} && @{ $self->{file_monkey} } ) {
		__load_module( MODULE_FILE_MONKEY )
		    or die( "Failed to load FileMonkey: $@" );
		%rslt = MODULE_FILE_MONKEY->import(
		    $self->{file_monkey} );
	    }
	    __load_module( 'App::AckX::Preflight::MiniAck' )
		or __die( "Failed to load MiniAck: $@" );
	    return App::AckX::Preflight::MiniAck->run( @arg );
	},
	DISPATCH_SYSTEM, sub {
	    my ( $self, @arg ) = @_;
	    @arg = $self->_build_ack_command( @arg );
	    system { $arg[0] } @arg;
	    $? == 0
		or $? == 0x100
		or __die( __interpret_exit_code( $? ) );
	    return $? >> 8;
	},
    };

    return $dispatch->{ $self->dispatch() }->(
	$self, @arg );
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

sub __plugins {
    my ( $self ) = @_;

    my %disable;
    ref $self
	and %disable = %{ $self->{disable} };
    my @rslt;
    foreach my $plugin ( @CARP_NOT ) {
	$plugin =~ PLUGIN_MATCH
	    or next;
	delete $disable{$plugin}
	    and next;
	__load_module( $plugin )
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
    if ( $self->{file_monkey} ) {
	state $json = JSON->new()->utf8()->pretty()->canonical();
	warn '$# File monkey: ', $json->encode( $self->{file_monkey} );
    }
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

=item dispatch

This argument can be C<'exec'>, C<'none'> or C<'system'>, or any unique
abbreviation thereof. The C<'exec'> and C<'system'> built-ins cause
F<ack> to be run using the same-named system built-in. The C<'none'>
value runs no external executable, but provides minimal functionality
specific to F<ack>.

See L<App::AckX::Preflight::MiniAck|App::AckX::Preflight::MiniAck> for
more details on the functionality provided when C<'none'> is specified.

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

This option applies only to the actual F<ack> run. If C<dispatch> is
C<'none'>, the old C<STDOUT> will be restored.

=item output_encoding

This is the encoding to be applied to the output. The default is
C<undef>, which specifies no explicit encoding.

This option applies only to the actual F<ack> run. If C<dispatch> is
C<'none'>, the old C<STDOUT> encoding will be restored.

=item verbose

This Boolean is the default verbosity setting. The default is C<0> (i.e.
false) which means non-verbose.

=back

If C<new()> is called as a normal method it clones its invocant,
applying the arguments (if any) after the clone.

=head2 dispatch

 say App::Ack::Preflight->dispatch();
 say $aaxp->dispatch();

If called on an object, this method returns the value of the
C<{dispatch}> attribute, whether explicit or defaulted. If called
statically, it returns the default value of the C<{dispatch}> attribute.

=head2 __file_monkey

 $self->__file_monkey( $class => \%config );

This method is B<private> to the C<App-AckX-Preflight> package. Its
documentation is solely for the benefit of the author and does not
constitute a commitment to the user. It can be changed or revoked at any
time. I<Caveat user.>

A plug-in would call this method to request
L<App::AckX::Preflight::FileMonkey|App::AckX::Preflight::FileMonkey> to
process the given class using the given configuration data. The class
B<must> implement static methods C<__setup()> and C<__post_open()>.

The C<__setup()> method is called by
L<App::AckX::Preflight::FileMonkey|App::AckX::Preflight::FileMonkey>'s
C<init()> method. It is passed a reference to the C<%config> hash. The
C<__setup()> method B<may> return a hash reference, which will
(ultimately) be returned to whoever called C<init()>, B<provided>, of
course, that this was not done in void context.  You almost certainly do
not want to return anything if C<init()> was called in void context.
Especially if you are returning L<Scope::Guard|Scope::Guard> objects to
do clean-up when
L<App::AckX::Preflight::MiniAck|App::AckX::Preflight::MiniAck>
completes.

The C<__post_open()> method is called in list context when a file is
opened for F<ack> to search. It is passed a reference to the C<%config>
hash, the file handle, and the L<App::Ack::File|App::Ack::File> object.
It B<must not> alter the file handle, but it B<may> return I/O layers to
be applied to the file handle after all C<__post_open()> methods are
called. These layers B<must> be returned without leading colons, and
B<must> be returned individually (i.e.

 return qw{ crlf encoding(utf-8) }

not

 return ':crlf:encoding(utf-8)'

).

The C<__post_open()> method B<must not> return I/O layers unless
it has checked to see that these have not already been applied.

See
L<App::AckX::Preflight::Plugin::Syntax|App::AckX::Preflight::Plugin::Syntax>
for an example of how to use this, and
L<App::AckX::Preflight::FileMonkey|App::AckX::Preflight::FileMonkey> for
implementation details.

The current C<FileMonkey> request list (a reference to an array of array
references) is returned. You can also call this with no arguments to
query the current contents of the C<FileMonkey> request list. If there
is none, nothing is returned.

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

=head2 output

 say App::Ack::Preflight->output();
 say $aaxp->output();

If called on an object, this method returns the value of the C<{output}>
attribute, whether explicit or defaulted. If called statically, it
returns the default value of the C<{output}> attribute.

=head2 output_encoding

 say App::Ack::Preflight->output_encoding();
 say $aaxp->output_encoding();

If called on an object, this method returns the value of the
C<{output_encoding}> attribute, whether explicit or defaulted. If called
statically, it returns the default value of the C<{output_encoding}>
attribute.

=head2 verbose

 say App::Ack::Preflight->verbose();
 say $aaxp->verbose();

If called on an object, this method returns the value of the
C<{verbose}> attribute, whether explicit or defaulted. If called
statically, it returns the default value of the C<{verbose}> attribute.

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
and then dispatches F<ack>, passing it C<@ARGV> as it stands after all
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

If the C<dispatch> argument is C<'exec'>, this method runs F<ack> via
C<exec()>, and B<does not return.>

If the C<dispatch> argument is C<'system'> (the default), this method
runs F<ack> via C<system()>. In this case, it dies if F<ack> signals, or
exits with any status but C<0> or C<1>. If it does not die, it returns
the exit status.

If the C<dispatch> argument is C<'none'>, this method does not run
F<ack> at all, and provides reduced functionality.

B<Windows note:> The C<exec> mechanism does not seem to do what I want
under Windows, so an attempt to set C<dispatch> to C<exec> will be
ignored with a warning.

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

Copyright (C) 2018-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
