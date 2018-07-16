package App::AckX::Preflight::Syntax::Fortran;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::_single_line_comments ();
use App::AckX::Preflight::Util ();

our @ISA;

our $VERSION;

BEGIN {
    App::AckX::Preflight::Util->import(
	qw{
	    :syntax
	    @CARP_NOT
	}
    );

    @ISA = qw{ App::AckX::Preflight::Syntax::_single_line_comments };

    $VERSION = '0.000_019';

    __PACKAGE__->__handles_type_mod( qw{ set fortran } );
}

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT );
}

sub __single_line_re {
    return qr{ \A (?: [C*] | \s* ! ) }smxi;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Fortran - App::AckX::Preflight syntax filter for Fortran.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Fortran file,
returning only those lines the user has requested.

This filter considers C<'D'> lines to be code. It is not possible in
general to distinguish commented-out code from comments in general, but
when it can be done it seems good sense to do it.

The supported syntax types are:

=over

=item code

=item comment

=back

=head1 METHODS

This class adds no new methods to its parent,
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>.

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>

L<App::AckX::Preflight|App::AckX::Preflight>

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
