package App::AckX::Preflight::Util;

use 5.008008;

use strict;
use warnings;

use App::Ack ();
use Carp ();
use Exporter qw{ import };
use Getopt::Long 2.39;	# For Getopt::Long::Parser->getoptionsfromarray()

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant REGEXP_REF	=> ref qr{};
use constant SCALAR_REF	=> ref \0;

use constant SYNTAX_CODE		=> 'code';
use constant SYNTAX_COMMENT		=> 'comment';
use constant SYNTAX_DATA		=> 'data';
use constant SYNTAX_DOCUMENTATION	=> 'documentation';
use constant SYNTAX_METADATA		=> 'metadata';
use constant SYNTAX_OTHER		=> 'other';

use constant FILE_ID_IS_INODE	=> ! { map { $_ => 1 }
    qw{ dos os2 MSWin32 VMS } }->{$^O};

use constant ACK_FILE_CLASS	=> do {
    ( my $version = App::Ack->VERSION() ) =~ s/ _ //smxg;
    $version ge '2.999' ? 'App::Ack::File' : 'App::Ack::Resource';
};

our $VERSION;
our @EXPORT_OK;
our %EXPORT_TAGS;
our @CARP_NOT;

BEGIN {

    $VERSION = '0.000_021';

    @EXPORT_OK = qw{
	__die
	__die_hard
	__err_exclusive
	__file_id
	__getopt
	__getopt_for_plugin
	__open_for_read
	__syntax_types
	__warn

	ACK_FILE_CLASS

	IS_SINGLE_FILE

	ARRAY_REF
	CODE_REF
	HASH_REF
	REGEXP_REF
	SCALAR_REF

	SYNTAX_CODE
	SYNTAX_COMMENT
	SYNTAX_DATA
	SYNTAX_DOCUMENTATION
	SYNTAX_METADATA
	SYNTAX_OTHER

	@CARP_NOT
    };

    %EXPORT_TAGS = (
	all		=> \@EXPORT_OK,
	croak	=> [ qw{ __die __die_hard __warn } ],
	ref		=> [ grep { m/ _REF \z /smx } @EXPORT_OK ],
	syntax	=> [ grep { m/ \A SYNTAX_ /smx } @EXPORT_OK ],
    );

    @CARP_NOT = qw{
	App::AckX::Preflight
	App::AckX::Preflight::Plugin
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Syntax
	App::AckX::Preflight::Syntax
	App::AckX::Preflight::Syntax::Ada
	App::AckX::Preflight::Syntax::Asm
	App::AckX::Preflight::Syntax::Batch
	App::AckX::Preflight::Syntax::Cc
	App::AckX::Preflight::Syntax::Cpp
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

    __PACKAGE__->can( 'IS_SINGLE_FILE' )
	or constant->import( IS_SINGLE_FILE => 0 );
}

sub __die {
    $Carp::Verbose
	and goto &Carp::confess;
    return CORE::die( _me(), ': ', @_, "\n" );
}

sub __die_hard {
    my @arg = @_;
    if ( @arg ) {
	$arg[0] = "Programming error - $arg[0]";
    } else {
	@arg = ( 'Programming error' );
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

{
    my $psr;	# Oh, for 5.10 and 'state'.

    sub __getopt {
	my ( @opt_spec ) = @_;
	$psr ||= _get_option_parser();
	my $source = ARRAY_REF eq ref $opt_spec[0] ? shift @opt_spec : \@ARGV;
	my $opt = HASH_REF eq ref $opt_spec[0] ? shift @opt_spec : {};
	$psr->getoptionsfromarray( $source, $opt, @opt_spec )
	    or __die( 'Invalid option on command line' );
	return $opt;
    }
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
	},
    );
    return $psr;
}

sub __getopt_for_plugin {
    my ( $plugin ) = @_;
    my $opt = {};
    if ( my @spec = $plugin->__options() ) {
	__getopt( $opt, @spec );
    }
    if ( my @spec = $plugin->__peek_opt() ) {
	__getopt( [ @ARGV ], $opt, @spec );
    }
    $plugin->__normalize_options( $opt );
    return $opt;
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
L<App::AckX::Preflight|App::AckX::Preflight>.

=head1 SUBROUTINES

This package can export the following subroutines. None are exported by
default.

=head2 __die

 __die( 'Goodbye, cruel world!' );

This subroutine dispatches to C<Carp::confess()> if C<$Carp::Verbose> is
true; otherwise it dispatches to C<App::Ack::die()>.

=head2 __die_hard

 __die_hard( 'Spewing my guts' );

This subroutine prefixes C<'Programming error - '> to its arguments and
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
L<Cwd::abs_path()|Cwd/abs_path>.

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

=head2 __open_for_read

 my $fh = __open_for_read( $file_name );

This subroutine opens the named file for reading. It is assumed to be
encoded C<UTF-8>. An exception is thrown if the open fails.

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

=head2 IS_SINGLE_FILE

This Boolean value will be true if running the single-file version.

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

=head2 ref

This tag exports everything that ends in C<'_REF'>.

=head2 syntax

This tag exports everything that starts with C<'SYNTAX_'>.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

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
