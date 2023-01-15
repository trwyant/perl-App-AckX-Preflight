package App::AckX::Preflight::Util;

use 5.010001;

use strict;
use warnings;

use Carp ();
use Exporter qw{ import };
use Getopt::Long 2.39;	# For Getopt::Long::Parser->getoptionsfromarray()
use JSON;
use Module::Load ();
use Text::ParseWords ();

use constant DEFAULT_OUTPUT	=> '-';

use constant EMPTY_STRING	=> q<>;

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant REGEXP_REF	=> ref qr{};
use constant SCALAR_REF	=> ref \0;

use constant IS_VMS	=> 'VMS' eq $^O;
use constant IS_WINDOWS	=> { map { $_ => 1 } qw{ dos MSWin32 } }->{$^O};

use constant MODULE_FILE_MONKEY	=> 'App::AckX::Preflight::FileMonkey';

use constant SYNTAX_CODE		=> 'code';
use constant SYNTAX_COMMENT		=> 'comment';
use constant SYNTAX_DATA		=> 'data';
use constant SYNTAX_DOCUMENTATION	=> 'documentation';
use constant SYNTAX_METADATA		=> 'metadata';
use constant SYNTAX_OTHER		=> 'other';

use constant FILE_ID_IS_INODE	=> ! { map { $_ => 1 }
    qw{ dos os2 MSWin32 VMS } }->{$^O};

use constant ACK_FILE_CLASS	=> 'App::Ack::File';

our $VERSION = '0.000_046';

our @EXPORT_OK = qw{
    __check_encoding
    __die
    __die_hard
    __err_exclusive
    __file_id
    __getopt
    __interpret_plugins
    __interpret_exit_code
    __json_decode
    __json_encode
    __load_ack_config
    __load_module
    __open_for_read
    __set_sub_name
    __syntax_types
    __warn

    ACK_FILE_CLASS

    DEFAULT_OUTPUT

    EMPTY_STRING

    ARRAY_REF
    CODE_REF
    HASH_REF
    REGEXP_REF
    SCALAR_REF

    IS_VMS
    IS_WINDOWS

    MODULE_FILE_MONKEY

    SYNTAX_CODE
    SYNTAX_COMMENT
    SYNTAX_DATA
    SYNTAX_DOCUMENTATION
    SYNTAX_METADATA
    SYNTAX_OTHER

    @CARP_NOT
};

our %EXPORT_TAGS = (
    all		=> \@EXPORT_OK,
    croak	=> [ qw{ __die __die_hard __warn } ],
    json	=> [ grep { m/ \A __json_ /smx } @EXPORT_OK ],
    module	=> [ grep { m/ \A MODULE_ /smx } @EXPORT_OK ],
    os		=> [ qw{ IS_VMS IS_WINDOWS } ],
    ref		=> [ grep { m/ _REF \z /smx } @EXPORT_OK ],
    syntax	=> [ grep { m/ \A SYNTAX_ /smx } @EXPORT_OK ],
);

our @CARP_NOT = qw{
    App::AckX::Preflight
    App::AckX::Preflight::Encode
    App::AckX::Preflight::FileMonkey
    App::AckX::Preflight::MiniAck
    App::AckX::Preflight::Plugin
    App::AckX::Preflight::Plugin::Encode
    App::AckX::Preflight::Plugin::Expand
    App::AckX::Preflight::Plugin::File
    App::AckX::Preflight::Plugin::Perldoc
    App::AckX::Preflight::Plugin::Syntax
    App::AckX::Preflight::Syntax
    App::AckX::Preflight::Syntax::Ada
    App::AckX::Preflight::Syntax::Asm
    App::AckX::Preflight::Syntax::Batch
    App::AckX::Preflight::Syntax::Cc
    App::AckX::Preflight::Syntax::Cpp
    App::AckX::Preflight::Syntax::Crystal
    App::AckX::Preflight::Syntax::Csharp
    App::AckX::Preflight::Syntax::Data
    App::AckX::Preflight::Syntax::Fortran
    App::AckX::Preflight::Syntax::Haskell
    App::AckX::Preflight::Syntax::Java
    App::AckX::Preflight::Syntax::Lisp
    App::AckX::Preflight::Syntax::Lua
    App::AckX::Preflight::Syntax::Make
    App::AckX::Preflight::Syntax::Ocaml
    App::AckX::Preflight::Syntax::Pascal
    App::AckX::Preflight::Syntax::Perl
    App::AckX::Preflight::Syntax::Python
    App::AckX::Preflight::Syntax::Raku
    App::AckX::Preflight::Syntax::SQL
    App::AckX::Preflight::Syntax::Shell
    App::AckX::Preflight::Syntax::Swift
    App::AckX::Preflight::Syntax::Vim
    App::AckX::Preflight::Syntax::YAML
    App::AckX::Preflight::Syntax::_cc_like
    App::AckX::Preflight::Syntax::_nesting
    App::AckX::Preflight::Syntax::_single_line_comments
    App::AckX::Preflight::Util
};

sub __check_encoding {
    my ( $encoding ) = @_;
    defined $encoding
	or return undef;	## no critic (ProhibitExplicitReturnUndef)
    $encoding eq EMPTY_STRING
	and return undef;	## no critic (ProhibitExplicitReturnUndef)
    my $enc = Encode::find_encoding( $encoding )
	or __die( "Encoding '$encoding' not found" );
    return $enc->name();
}

sub __die {
    $Carp::Verbose
	and goto &Carp::confess;
    return CORE::die( _me(), ': ', @_, "\n" );
}

sub __die_hard {
    my @arg = @_;
    if ( @arg ) {
	$arg[0] = "Bug - $arg[0]";
    } else {
	@arg = ( 'Bug' );
    }
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::confess( @arg );
}

sub __file_id {
    my ( $path ) = @_;
    return FILE_ID_IS_INODE ?
	join( ':', ( stat $path )[ 0, 1 ] ) :
	Cwd::abs_path( $path );
}

sub __getopt {
    my ( @opt_spec ) = @_;
    state $psr = _get_option_parser();
    my $source = ARRAY_REF eq ref $opt_spec[0] ? shift @opt_spec : \@ARGV;
    my $opt = HASH_REF eq ref $opt_spec[0] ? shift @opt_spec : {};
    $psr->getoptionsfromarray( $source, $opt, @opt_spec )
	or __die( 'Invalid option on command line' );
    return $opt;
}

sub __err_exclusive {
    my @arg = @_;
    2 == @arg
	or __die_hard( '__err_exclusive() requires 2 arguments' );
    __die( "Options --$arg[0] and --$arg[1] are mutually exclusive." );
}

sub _get_option_parser {
    my $psr = Getopt::Long::Parser->new();
    $psr->configure( qw{
	no_auto_version no_ignore_case no_auto_abbrev pass_through
	bundling
	},
    );
    return $psr;
}

sub __interpret_exit_code {
    my ( $num ) = @_;
    $num == -1
	and return "Failed to execute command: $!";
    $num & 0x7F
	and return sprintf 'Child died with signal %s, %s coredump',
	    _sig_num( $num ), $num & 0x80 ? 'with' : 'without';
    return sprintf 'Child exited with value %d', $num >> 8;
}

sub __interpret_plugins {
    my ( @plugin_list ) = @_;
    my $default = ( HASH_REF eq ref $plugin_list[0] ) ? shift @plugin_list : {};

    my %plugin_info;

    # Parse the "Peek" options, but leave them in @ARGV.
    foreach my $plugin ( @plugin_list ) {
	$plugin_info{$plugin} = my $info = {
	    class	=> $plugin,
	    opt		=> {},
	    order	=> @ARGV + 1,
	    priority	=> $plugin->DISPATCH_PRIORITY(),
	};

	if ( my @spec = _mung_options( $info, $plugin->__peek_opt() ) ) {
	    __getopt( [ @ARGV ], $info->{opt}, @spec );
	}
    }

    # Parse the main options, determining plug-in order based on option
    # position in @ARGV.
    foreach my $plugin ( @plugin_list ) {
	my $info = $plugin_info{$plugin};
	local $info->{compute_order} = 1;
	if ( my @spec = _mung_options( $info, $plugin->__options() ) ) {
	    __getopt( $info->{opt}, @spec );
	}
    }

    # Supply default values from other plug-ins.
    {
	my @arg;
	foreach ( @plugin_list ) {
	    my $name = $_->__name();
	    $default->{$name}
		and $_->__wants_to_run( $plugin_info{$_}{opt} )
		and push @arg, Text::ParseWords::shellwords( $default->{$name} );
	}

	if ( @arg ) {
	    local @ARGV = @arg;
	    foreach my $plugin ( @plugin_list ) {
		my $info = $plugin_info{$plugin};
		my $i2 = { opt => {} };
		if ( my @spec = _mung_options( $i2, $plugin->__options() ) ) {
		    __getopt( $i2->{opt}, @spec );
		    foreach my $key ( keys %{ $i2->{opt} } ) {
			exists $info->{opt}{$key}
			    or $info->{opt}{$key} = $i2->{opt}{$key};
		    }
		}
	    }
	}
    }

    foreach my $plugin ( @plugin_list ) {
	$plugin->__normalize_options( $plugin_info{$plugin}{opt} );
    }

    return(
	sort
	    {
		$b->{priority} <=> $a->{priority} ||
		$a->{order} <=> $b->{order} ||
		$a->{class} cmp $b->{class}
	    }
	    values %plugin_info
    );
}

sub _mung_options {
    my ( $info, @spec ) = @_;
    @spec
	or return;
    my $opt = $info->{opt} ||= {};
    my @s;
    foreach my $os ( @spec ) {
	my $ref = ref $os;
	if ( $ref eq CODE_REF ) {
	    if ( $info->{compute_order} ) {
		pop @s;
		push @s, sub {
		    $info->{order} = @ARGV;
		    $os->( @_, $opt );
		    return;
		};
	    } else {
		push @s, sub { $os->( @_, $opt ) };
	    }
	} elsif ( $ref ) {
	    __die_hard( "$ref reference bod supported" );
	} elsif ( $info->{compute_order} ) {
	    push @s, $os, index( $os, '%' ) >= 0 ?
		sub {	# Hash option 
		    $opt->{$_[0]}{$_[1]} = $_[2];
		    $info->{order} = @ARGV;
		} : index( $os, '@' ) >= 0 ?
		sub {	# Array option
		    push @{ $opt->{$_[0]} }, $_[1];
		    $info->{order} = @ARGV;
		} :
		sub {	# Scalar option
		    $opt->{$_[0]} = $_[1];
		    $info->{order} = @ARGV;
		};
	} else {
	    push @s, $os;
	}
    }
    return @s;
}

sub __json_decode {
    my ( $string ) = @_;
    $string =~ s/ % ( [[:xdigit:]]+ ) ; / chr hex $1 /smxge;
    state $json = JSON->new()->utf8();
    return $json->decode( $string );
}

sub __json_encode {
    my ( $data ) = @_;
    state $json = JSON->new()->utf8()->canonical();
    my $string = $json->encode( $data );
    $string =~ s/ ( [^\w:-] ) / sprintf '%%%x;', ord $1 /smxge;
    return $string;
}

sub __load_ack_config {
    state $loaded = do {	## no critic (ProhibitUnusedVarsStricter)
	unless ( keys %App::Ack::mappings ) {
	    # Hide these from xt/author/prereq.t, since we do not execute
	    # this code when called from the hot patch, which is the normal
	    # path through the code. It is needed for (e.g.) tools/number.
	    __load_module( $_ ) for qw{
		App::Ack::ConfigLoader
		App::Ack::Filter
		App::Ack::Filter::Default
		App::Ack::Filter::Extension
		App::Ack::Filter::FirstLineMatch
		App::Ack::Filter::Inverse
		App::Ack::Filter::Is
		App::Ack::Filter::IsPath
		App::Ack::Filter::Match
		App::Ack::Filter::Collection
	    };
	}
    };
    my @arg_sources = App::Ack::ConfigLoader::retrieve_arg_sources();
    return App::Ack::ConfigLoader::process_args( @arg_sources );
}

sub __load_module {
    my ( $module ) = @_;
    return eval {
	Module::Load::load( $module );
	1;
    };
}

sub _me {
    return( ( File::Spec->splitpath( $0 ) )[2] );
}

sub __open_for_read {
    my ( $path ) = @_;
    open my $fh, '<:encoding(utf-8)', $path
	or __die( "Unable to open $path: $!" );
    return $fh;
}

{
    local $@ = undef;
    *__set_sub_name = eval {
	__load_module( 'Sub::Util' ) && Sub::Util->can( 'set_subname' );
    } || eval {
	__load_module( 'Sub::Name' ) && Sub::Name->can( 'subname' );
    } || sub { return $_[1] };
}
__set_sub_name( __set_sub_name => \&__set_sub_name );

sub _sig_num {
    my ( $num ) = @_;
    $num &= 0x7F;
    local $@ = undef;
    __require( 'Config' )
	or return sprintf '%d', $num;
    my @sig;
    @sig[ split / /, $Config::Config{sig_num} ] =
	split / /, $Config::Config{sig_name};
    return sprintf '%d ( SIG%s )', $num, $sig[$num];
}

sub __syntax_types {
    return ( map { __PACKAGE__->$_() } @{ $EXPORT_TAGS{syntax} } );
}

sub __warn {
    return CORE::warn( _me(), ': ', @_, "\n" );
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Util - Utility functions.

=head1 SYNOPSIS

 use App::AckX::Preflight::Util qw{ :all };

 my $fh = __open_for_read( $fubar );

=head1 DESCRIPTION

This Perl module provides utility functions for
L<App::AckX::Preflight|App::AckX::Preflight>. Its contents are
B<private> to the C<App-AckX-Preflight> distribution, and can be changed
or revoked at any time and without notice. This documentation is for the
convenience of the author only, and does not constitute an interface
contract with the user of this package.

=head1 SUBROUTINES

This package can export the following subroutines. None are exported by
default.

=head2 __die

 __die( 'Goodbye, cruel world!' );

This subroutine dispatches to C<Carp::confess()> if C<$Carp::Verbose> is
true; otherwise it dispatches to C<App::Ack::die()>.

=head2 __die_hard

 __die_hard( 'Spewing my guts' );

This subroutine prefixes C<'Bug - '> to its arguments and
then calls C<Carp::confess()>.

=head2 __err_exclusive

 __err_exclusive( 'foo', 'bar' );
 # ackxp: Options --foo and --bar are mutually exclusive.

This subroutine dies with an error saying that the two arguments are
mutually exclusive options. The arguments are the bare names of the
options; the leading double dash is provided by this code.

=head2 __file_id

 my $file_id = __file_id( $file_name );

This subroutine returns a unique ID for a file. If two files have the
same ID it means that they are the same file. The user of this ID should
treat it as an opaque string.

That being said, the return is normally the file's device and inode
numbers (as reported by C<stat()>), joined by a colon (C<':'>), except
for systems where F<perlport> says this is not meaningful or reliable.
For such systems it is the full path name of the file as determined by
L<Cwd::abs_path()|Cwd/abs_path and friends>.

In this implementation, the device and inode are used for all values of
C<$^O> except C<'dos'>, C<'os2'>, C<'VMS'>, and C<'MSWin32'>. I am
somewhat surprised not to find C<'cygwin'> on the F<perlport> list.

=head2 __getopt

 my $opt = __getopt( qw{ foo! bar=s } );

This subroutine is intended for the use of plug-ins that want to process
their own options. It actually calls C<getoptionsfromarray()>, with the
array being the first argument if it is an array reference, or C<\@ARGV>
if not, and the options hash being the next argument if it is a hash
reference, and an empty hash if not. All other arguments are
L<Getopt::Long|Getopt::Long> option specifications. Any options actually
processed are removed from the array. The return is a reference to the
options hash.

The actual configuration used is

 no_auto_version no_ignore_case no_auto_abbrev pass_through

which is what L<App::Ack|App::Ack> uses.

=head2 __getopt_for_plugin

 my $opt = __getopt_for_plugin( $plugin_class_name );

This subroutine is really exposed for the convenience of plugin unit
testing. It calls the plugin's
L<__options()|App::AckX::Preflight::Plugin/__options> and
L<__peek_opt()|App::AckX::Preflight::Plugin/__peek_opt> methods to
determine which options to parse, and returns a reference to the options
hash.

=head2 __interpret_exit_code

 say __interpret_exit_code( $? )

This subroutine takes as its argument a subprocess exit code, and
returns a string interpreting that code. Its implementation leans
heavily on the example given in L<perlop> under C<qx/*STRING*/>.

=head2 __interpret_plugins

 my @plugins = __interpret_plugins( $self->__plugins() );

This subroutine takes as its argument a list of plugin class names and
returns an array of hashes. Each hash describes a plugin, with the
following keys:

=over

=item class

This is the class name of the plugin.

=item opt

These are the command-line options for the plugin. These come from
either the plugin's C<__options()> method or its C<__peek_opt()> method.
Only in the former case are options removed from C<@ARGV>.

B<Note> that options can specify code references as handlers, These are
called per the L<Getopt::Long|Getopt::Long> documentation, but a
reference to the options hash is appended to the argument list.

=item order

This is the processing order for the plugin, determined from the order
the options were encountered in the command line.

=item priority

This is just a copy of the plugin's C<DISPATCH_PRIORITY>.

=back

The plugins are returned in descending order of the C<{priority}> key,
and within a priority in ascending order of the C<{order}> key.

Optionally, the first argument can be a reference to a hash of default
arguments, keyed by plugin name (as returned by C<__name()>). For each
specified plugin, if its C<__wants_to_run()> method returns a true
value, the default arguments are parsed with
C<Text::ParseWords::shellwords()> and then by each enabled plug-in. Any
options found are used as default options for the relevant plug-ins.

=head2 __load_ack_config

This subroutine loads whatever F<ack> configuration this distribution
needs to do its job. It takes no arguments and returns a reference to
the parsed configuration.

This subroutine is idempotent, so the only overhead in calling it
multiple times is the overhead of a subroutine call plus that of
checking that stuff has already been loaded.

=head2 __load_module

 __load_module( 'Foo::Bar' );

This subroutine loads the named module, returning a Boolean value that
says whether the module was successfully loaded.

=head2 __open_for_read

 my $fh = __open_for_read( $file_name );

This subroutine opens the named file for reading. It is assumed to be
encoded C<UTF-8>. An exception is thrown if the open fails.

=head2 __set_sub_name

 my $code_ref = __set_sub_name( fubar => sub { die 'snafu' } );

This subroutine attempts to set the subroutine name of a code reference.
The code reference is returned.

The heavy lifting is done by L<Sub::Util|Sub::Util> if that can be
loaded, or by L<Sub::Name|Sub::Name> if B<that> can be loaded.

If neither module can be loaded,  a dummy is provided that simply
returns its second argument.

=head2 __syntax_types

 say for __syntax_types();

This subroutine returns all defined syntax types; that is to say, the
values of all defined C<SYNTAX_*> constants.

=head2 __warn

 __warn( q<Don't jump!> );

This subroutine is really just an alias for C<App::Ack::warn()>.

=head1 MANIFEST CONSTANTS

This package can export the following manifest constants. None are
exported by default.

=head2 ACK_FILE_CLASS

This is the name of the Ack class that represents a file. It is
C<'App::Ack::File'> if the version of L<App::Ack|App::Ack> is at least
C<2.999>; otherwise it is C<'App::Ack::Resource'>.

=head2 DEFAULT_OUTPUT

This is the string that the C<--OUT> option uses to indicate default
output. Its value is C<'-'>;

=head2 EMPTY_STRING

This is just an empty string.

=head2 ARRAY_REF

This is set to C<ref []>.

=head2 CODE_REF

This is set to C<ref sub {}>.

=head2 HASH_REF

This is set to C<ref {}>.

=head2 REGEXP_REF

This is set to C<ref qr{}>.

=head2 SCALAR_REF

This is set to C<ref \0>.

=head2 IS_VMS

This is set to a true value if and only if the operating system is VMS.

=head2 IS_WINDOWS

This is set to a true value if and only if the operating system is
Windows.

=head2 MODULE_FILE_MONKEY

This is a convenience constant representing the string
L<'App::AckX::Preflight::FileMonkey'|App::AckX::Preflight::FileMonkey>.

=head2 SYNTAX_CODE

This is the recommended syntax filter specification for code, and is set
to C<'code'>.

=head2 SYNTAX_COMMENT

This is the recommended syntax filter specification for comments, and is
set to C<'comment'>.

=head2 SYNTAX_DATA

This is the recommended syntax filter specification for inline data, and
is set to C<'data'>.

=head2 SYNTAX_DOCUMENTATION

This is the recommended syntax filter specification for inline
documentation, and is set to C<'documentation'>.

=head2 SYNTAX_OTHER

This is the recommended syntax filter specification for anything else,
and is set to C<'other'>.

=head1 EXPORT TAGS

The following export tags can be used.

=head2 all

This tag exports everything that can be exported.

=head2 croak

This tag exports L<__die|/__die>, L<__die_hard|/__die_hard>, and
L<__warn|/__warn>.

=head2 module

This tag exports everything that begins with C<'MODULE_'>.

=head2 os

This tag exports L<IS_VMS|/IS_VMS> and L<IS_WINDOWS|/IS_WINDOWS>.

=head2 ref

This tag exports everything that ends in C<'_REF'>.

=head2 syntax

This tag exports everything that starts with C<'SYNTAX_'>.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

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
