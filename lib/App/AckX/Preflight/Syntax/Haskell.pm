package App::AckX::Preflight::Syntax::Haskell;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax::_cc_like };

use App::AckX::Preflight::Util qw{
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_018';

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT, SYNTAX_DOCUMENTATION );
}

__PACKAGE__->__handles_type_mod( qw{ set haskell } );

sub __comments_continue_doc {
    return 1;
}

sub __block_re {
    return(
	qr< \A \s* [{] - >smx,
	sub { return qr< - [}] >smx },
    );
}

sub __in_line_doc_re {
    return(
	qr< \A \s* [{] - \s* [|^] >smx,
	sub { return qr< - [}] >smx },
    );
}

sub __single_line_doc_re {
    return qr{ \A \s* -- \s* [|^] }smx;
}

sub __single_line_re {
    return qr{ \A \s* -- }smx;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Haskell - App::AckX::Preflight syntax filter for C++-like languages.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a C++-like file,
returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment (both C</* ... */>-style block and C<//> single-line)

=item documentation (block comments introduced by '/**')

=back

In principal this syntax filter can be used for any syntax that consists
of code, single-line comments introduced by C<'//'>, block comments
enclosed in C<'/* ... */'>, and in-line documentation enclosed in
C<'/** ... */'>.  By default it applies to:

=over

=item c<actionscript>

=item C<cpp>

=item C<go>

=item C<objc>

=item C<objcpp>

=back

=head1 METHODS

This class is a subclass of
L<App::AckX::Preflight::Syntax::_cc_like|App::AckX::Preflight::Syntax::_cc_like>.
It overrides the following methods:

=head2 __handles_syntax

=head2 __in_line_doc_re

This recognizes C<'/** ... */'> as documentation, not comments.

=head2 __single_line_re

This recognizes C<'//'> as a single-line comment.

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
