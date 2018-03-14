package App::AckX::Preflight::Util;

use 5.008008;

use strict;
use warnings;

use App::Ack ();
# use Carp ();
use Exporter qw{ import };

our $VERSION = '0.000_001';

our @EXPORT_OK = qw{
    __die
    __open_for_read
    __warn

    ARRAY_REF
    SCALAR_REF
};

our %EXPORT_TAGS = (
    all	=> \@EXPORT_OK,
    ref	=> [ grep { m/ _REF \z /smx } @EXPORT_OK ],
);

use constant ARRAY_REF	=> ref [];
use constant SCALAR_REF	=> ref \0;

*__die = \&App::Ack::die;	# sub __die

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
