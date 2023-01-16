package App::AckX::Preflight::Syntax::Batch;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax::_single_line_comments };

use App::AckX::Preflight::Util qw{ :syntax @CARP_NOT };

our $VERSION = '0.000_047';

__PACKAGE__->__handles_type_mod( qw{ set batch } );

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT );
}

sub __single_line_re {
    return qr{ \A (?: :: | \s* \@? rem \b ) }smxi;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Batch - App::AckX::Preflight syntax filter for shell-like syntax.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Batch file,
returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment

Comments include the C<'rem'> command (case-blind, and with or without
leading C<'@'>) and C<'::'> as the first two characters on a line.

Dead code (between an unconditional C<goto> and the next label) is not
considered a comment, mostly because detecting it seemed to involve more
parsing than I felt like doing.

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
