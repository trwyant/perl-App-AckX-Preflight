package App::AckX::Preflight::Syntax::Cc;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax::_cc_like };

use App::AckX::Preflight::Util qw{ :syntax @CARP_NOT };

our $VERSION = '0.000_048';

__PACKAGE__->__handles_type_mod( qw{ set cc css less } );

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT );
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Cc - App::AckX::Preflight syntax filter for C-like files.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a C or css file,
returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment (both block and single-line)

=back

In principal this syntax filter can be used for any syntax that consists
solely of code and C-style comments. By default it applies to:

=over

=item cc

=item css

=item less

=back

Note that we account for builtin type C<hh> in the C++ syntax filter.

=head1 METHODS

This class is a subclass of
L<App::AckX::Preflight::Syntax::_cc_like|App::AckX::Preflight::Syntax::_cc_like>.
It overrides the following methods:

=head2 __handles_syntax

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>

L<App::AckX::Preflight|App::AckX::Preflight>

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
