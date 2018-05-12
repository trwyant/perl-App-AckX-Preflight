package App::AckX::Preflight::Syntax::_single_line_comments;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{
    :croak
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_010';

sub __handles_syntax {
    __die_hard( '__handles_syntax() must be overridden' );
}

sub FILL {
    my ( $self, $fh ) = @_;
    {
	defined( my $line = <$fh> )
	    or last;
	my $type = $line =~ $self->{single_line_comment_re} ?
	    SYNTAX_COMMENT :
	    SYNTAX_CODE;
	$self->{want}{$type}
	    and return $line;
	redo;
    }
    return;
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;
    return bless {
	want			=> $class->__want_syntax(),
	single_line_comment_re	=> $class->__single_line_comment_re(),
    }, ref $class || $class;
}

sub __single_line_comment_re {
    __die_hard( '__single_line_comment_re() must be overridden' );
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::_single_line_comments - App::AckX::Preflight syntax filter for languages which only have single-line comments.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This Perl class is intended to be subclassed to produce a
This L<PerlIO::via|PerlIO::via> I/O layer used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a language whose
syntax allows only single-line comments, and no in-line data or
documentation.

In order to use this as a superclass, the subclass B<must> override
L<__handles_syntax|App::AckX::Preflight::Syntax/__handles_syntax> and
L<__single_line_comment_re()|/__single_line_comment_re>.

=head1 METHODS

This class adds the following methods:

=head2 __single_line_comment_re

This method returns a regular expression that matches a comment line, or
nothing if the syntax does not support single-line comments.

This method B<must> be overridden by a subclass.

=head2 PUSHED

This static method is part of the L<PerlIO::via|PerlIO::via> interface.
It is called when this class is pushed onto the stack.  It manufactures,
initializes, and returns a new object.

=head2 FILL

This method is part of the L<PerlIO::via|PerlIO::via> interface. It is
called when a C<readline>/C<< <> >> operator is executed on the file
handle. It reads the next-lower-level layer until a line is found that
is one of the syntax types that is being returned, and returns that line
to the next-higher layer. At end of file, nothing is returned.

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
