package App::AckX::Preflight::Syntax::SQL;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax::_cc_like };

use App::AckX::Preflight::Util qw{
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_009';

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT );
}

__PACKAGE__->__handles_type_mod( qw{ set sql } );

=begin comment

sub __in_line_documentation_re {
    return qr{ \A \s* / [*] [*] }smx;
}

=end comment

=cut

sub __single_line_comment_re {
    return qr{ \A \s* -- }smx;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::SQL - App::AckX::Preflight syntax filter for SQL.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process an SQL file,
returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment (both block and single-line)

=back

=head1 METHODS

This class adds the following methods, which are part of the
L<PerlIO::via|PerlIO::via> interface:

=head2 PUSHED

This static method is called when this class is pushed onto the stack.
It manufactures, initializes, and returns a new object.

=head2 FILL

This method is called when a C<readline>/C<< <> >> operator is executed
on the file handle. It reads the next-lower-level layer until a line is
found that is one of the syntax types that is being returned, and
returns that line to the next-higher layer. At end of file, nothing is
returned.

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