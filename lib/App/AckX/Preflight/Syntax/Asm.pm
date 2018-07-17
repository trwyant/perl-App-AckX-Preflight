package App::AckX::Preflight::Syntax::Asm;

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

    $VERSION = '0.000_021';

    __PACKAGE__->__handles_type_mod( qw{ set asm } );
}

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT, SYNTAX_METADATA );
}

sub __shebang_re {
    return;
}

sub __single_line_re {
    return qr{ \A \s* [;\#] }smx;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Asm - App::AckX::Preflight syntax filter for shell-like syntax.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Asm file,
returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment

=item metadata (the shebang line)

=back

In principal this syntax filter can be used for any syntax that consists
of code and single-line comments introduced by C<'#'>. By default it
applies to:

=over

=item python

=item shell

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
