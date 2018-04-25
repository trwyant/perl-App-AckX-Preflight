package App::AckX::Preflight::Util;

use 5.008008;

use strict;
use warnings;

use App::Ack ();
use Carp ();
use Exporter qw{ import };
use Getopt::Long 2.39;	# For Getopt::Long::Parser->getoptionsfromarray()

our $VERSION = '0.000_005';

our @EXPORT_OK = qw{
    __die
    __err_exclusive
    __file_id
    __getopt
    __getopt_for_plugin
    __open_for_read
    __warn

    ARRAY_REF
    HASH_REF
    SCALAR_REF
};

our %EXPORT_TAGS = (
    all	=> \@EXPORT_OK,
    ref	=> [ grep { m/ _REF \z /smx } @EXPORT_OK ],
);

use constant ARRAY_REF	=> ref [];
use constant HASH_REF	=> ref {};
use constant SCALAR_REF	=> ref \0;

use constant FILE_ID_IS_INODE	=> ! { map { $_ => 1 }
    qw{ dos os2 MSWin32 VMS } }->{$^O};

*__die = \&App::Ack::die;	# sub __die

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

sub __err_exclusive {	## no critic (RequireFinalReturn)
    my @arg = @_;
    2 == @arg
	or Carp::confess( '__err_exclusive() requires 2 arguments' );
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
    return $opt;
}

sub __open_for_read {
    my ( $path ) = @_;
    open my $fh, '<:encoding(utf-8)', $path
	or App::Ack::die( "Unable to open $path: $!" );
    return $fh;
}

*__warn = \&App::Ack::warn;	# sub __warn

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

This subroutine is really just an alias for C<App::Ack::die()>.

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

=head2 __warn

 __warn( q<Don't jump!> );

This subroutine is really just an alias for C<App::Ack::warn()>.

=head1 MANIFEST CONSTANTS

This package can export the following manifest constants. None are
exported by default.

=head2 ARRAY_REF

This is set to C<ref []>.

=head2 SCALAR_REF

This is set to C<ref \0>.

=head1 EXPORT TAGS

The following export tags can be used.

=head2 all

This tag exports everything that can be exported.

=head2 ref

This tag exports everything that ends in C<'_REF'>.

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
