package App::AckX::Preflight::Syntax::_cc_like;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{
    :croak
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_008';

sub __handles_syntax {
    __die_hard( '__handles_syntax() must be overridden' );
}

my %cmt_or_doc = map { $_ => 1 } SYNTAX_COMMENT, SYNTAX_DOCUMENTATION;

sub FILL {
    my ( $self, $fh ) = @_;
    {
	defined( my $line = <$fh> )
	    or last;

	if ( $cmt_or_doc{$self->{in}} ) {
	    if ( $line =~ m< [*] / >smx ) {
		my $was = $self->{in};
		$self->{in} = SYNTAX_CODE;
		# We have to hand-dispatch the line because although the
		# next line is code, the end of the block comment is
		# doc.
		$self->{want}{$was}
		    and return $line;
		redo;
	    }
	} elsif ( SYNTAX_CODE eq $self->{in} ) {
	    if ( $self->{in_line_doc_re} &&
		$line =~ $self->{in_line_doc_re} ) {
		$self->{in} = SYNTAX_DOCUMENTATION;
	    } elsif ( $line =~ m< \A \s* / [*] >smx ) {
		$self->{in} = SYNTAX_COMMENT;
	    } elsif ( $self->{single_line_comment_re} &&
		$line =~ $self->{single_line_comment_re} ) {
		$self->{want}{ SYNTAX_COMMENT() }
		    and return $line;
		redo;
	    }
	}
	$self->{want}{$self->{in}}
	    and return $line;
	redo;
    }
    return;
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;
    return bless {
	in			=> SYNTAX_CODE,
	want			=> $class->__want_syntax(),
	single_line_comment_re	=> $class->__single_line_comment_re(),
	in_line_doc_re		=> $class->__in_line_documentation_re(),
    }, ref $class || $class;
}

sub __single_line_comment_re {
    return;
}

sub __in_line_documentation_re {
    return;
}


1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::_cc_like - App::AckX::Preflight syntax filter for languages whose comment rules are similar to C.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This Perl class is intended to be subclassed to produce a
This L<PerlIO::via|PerlIO::via> I/O layer used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a file with
F<C>-like syntax. Specifically:

=over

=item Block comments begin with C</*>;

=item In-line documentation, if any, looks sort of like the beginning of
a block comment;

=item Single-line comments, if any, occur only in code.

=back

In order to use this as a superclass, the subclass B<must> override
L<__handles_syntax|App::AckX::Preflight::Syntax/__handles_syntax> and
L<__handles_type|App::AckX::Preflight::Syntax/__handles_type>. See the
documentation of
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax> for details.

The subclass B<may> override
L<__single_line_comment_re()|/__single_line_comment_re> and/or
L<__in_line_documentation_re()|/__in_line_documentatio_re>. If it does
not, it gets a syntax like C itself, without single-line comments or
in-line documentation.

=head1 METHODS

This class adds the following methods:

=head2 __single_line_comment_re

This method returns a regular expression that matches a comment line, or
nothing if the syntax does not support single-line comments.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having single-line comments.

=head2 __in_line_documentation_re

This method returns a regular expression that matches the beginning of
in-line documentation, or nothing if the syntax does not support in-line
documentation.

If this regular expression is provided it is tried before block
comments.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having in-line documentation.

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
under the same terms as _cc_like 5.10.0. For more details, see the full
text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
