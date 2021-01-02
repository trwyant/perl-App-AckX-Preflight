package App::AckX::Preflight::Syntax::Csharp;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::_cc_like ();
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

    @ISA = qw{ App::AckX::Preflight::Syntax::_cc_like };

    $VERSION = '0.000_029';

    __PACKAGE__->__handles_type_mod( qw{ set csharp } );
}

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT, SYNTAX_DOCUMENTATION );
}

sub __single_line_re {
    return qr{ \A \s* // }smx;
}

sub __single_line_doc_re {
    return qr{ \A \s* /// }smx;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Csharp - App::AckX::Preflight syntax filter for C#.

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

=item documentation (single-line comments introduced by '///')

=back

=head1 METHODS

This class adds no new methods to its parent,
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>.

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>

L<App::AckX::Preflight|App::AckX::Preflight>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
