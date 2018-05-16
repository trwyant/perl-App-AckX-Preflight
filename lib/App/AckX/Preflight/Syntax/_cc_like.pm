package App::AckX::Preflight::Syntax::_cc_like;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{
    :croak
    :ref
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_013';

sub __handles_syntax {
    __die_hard( '__handles_syntax() must be overridden' );
}

my $handler = {	# Anticipating 'state'.
    SYNTAX_CODE()		=> sub {
	my ( $self ) = @_;

	if ( $self->{in_line_doc_start} && $_ =~ $self->{in_line_doc_start} ) {
	    my $block_end = $self->_get_block_end(
		in_line_doc_end => $1 );
	    $_ =~ $block_end
		and return $self->{want}{ SYNTAX_DOCUMENTATION() };
	    $self->{_in_line_doc_end} = $block_end;
	    $self->{in} = SYNTAX_DOCUMENTATION;
	} elsif ( $self->{block_start} && $_ =~ $self->{block_start} ) {
	    my $block_end = $self->_get_block_end( block_end => $1 );
	    $_ =~ $block_end
		and return $self->{want}{ SYNTAX_COMMENT() };
	    $self->{_block_end} = $block_end;
	    $self->{in} = SYNTAX_COMMENT;
	} elsif ( $self->{single_line_doc_re} &&
	    $_ =~ $self->{single_line_doc_re} ) {
	    return $self->{want}{ SYNTAX_DOCUMENTATION() };
	} elsif ( $self->{single_line_re} && $_ =~ $self->{single_line_re} ) {
	    return $self->{want}{ SYNTAX_COMMENT() };
	}
	return $self->{want}{ $self->{in} };
    },
    SYNTAX_COMMENT()		=> sub {
	my ( $self ) = @_;

	if ( $_ =~ $self->{_block_end} ) {
	    my $was = $self->{in};
	    $self->{in} = SYNTAX_CODE;
	    delete $self->{_block_end};
	    # We have to hand-dispatch the line because although the
	    # next line is code, the end of the block comment is doc.
	    return $self->{want}{$was};
	} else {
	    return $self->{want}{ $self->{in} };
	}

	return;
    },
    SYNTAX_DOCUMENTATION()	=> sub {
	my ( $self ) = @_;

	if ( $_ =~ $self->{_in_line_doc_end} ) {
	    my $was = $self->{in};
	    $self->{in} = SYNTAX_CODE;
	    delete $self->{_in_line_doc_end};
	    # We have to hand-dispatch the line because although the
	    # next line is code, the end of the block comment is doc.
	    return $self->{want}{$was};
	} else {
	    return $self->{want}{ $self->{in} };
	}

	return;
    },
};

sub FILL {
    my ( $self, $fh ) = @_;

    local $_ = undef;	# Should not be needed, but seems to be.

    while ( <$fh> ) {
	$handler->{ $self->{in} }->( $self )
	    and return $_;
    }
    return;
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;
    my $single_line_re = $class->_validate_single_line(
	'__single_line_re()', $class->__single_line_re() );
    my $single_line_doc_re = $class->_validate_single_line(
	'__single_line_doc_re()', $class->__single_line_doc_re() );
    my ( $block_start, $block_end ) = $class->_validate_block(
	'__block_re()', $class->__block_re() );
    my ( $in_line_doc_start, $in_line_doc_end ) = $class->_validate_block(
	'__in_line_doc_re()', $class->__in_line_doc_re() );
    return bless {
	in			=> SYNTAX_CODE,
	want			=> $class->__want_syntax(),
	block_start		=> $block_start,
	block_end		=> $block_end,
	in_line_doc_start	=> $in_line_doc_start,
	in_line_doc_end		=> $in_line_doc_end,
	single_line_re		=> $single_line_re,
	single_line_doc_re	=> $single_line_doc_re,
    }, ref $class || $class;
}

sub _get_block_end {
    my ( $self, $kind, $start ) = @_;
    REGEXP_REF eq ref $self->{$kind}
	and return $self->{$kind};
    return $self->{$kind}{$start} || __die_hard(
	"No block end corresponds to '$start'" );
}

sub _validate_block {
    my ( undef, $kind, $start, $end ) = @_;
    defined $start
	or return;
    REGEXP_REF eq ref $start
	or __die_hard( "$kind start must be regexp or undef" );
    REGEXP_REF eq ref $end
	and return ( $start, $end );
    HASH_REF eq ref $end
	or __die_hard( "$kind end must be regexp or hash ref" );
    __any { REGEXP_REF ne ref } values %{ $end }
	and __die_hard( "$kind end hash values must be regexp" );
    return ( $start, $end );
}

sub _validate_single_line {
    my ( undef, $kind, $re ) = @_;
    defined $re
	or return;
    REGEXP_REF eq ref $re
	or __die_hard( "$kind must return regexp or undef" );
    return $re;
}

sub __block_re {
    return(
	qr{ \A \s* / [*] }smx,
	qr{ [*] / }smx,
    );
}

sub __in_line_doc_re {
    return;
}

sub __single_line_doc_re {
    return;
}

sub __single_line_re {
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
L<__handles_syntax|App::AckX::Preflight::Syntax/__handles_syntax>. Also,
it B<must> call
L<__handles_type_mod|App::AckX::Preflight::Syntax/__handles_type_mod> to
set up the types of files handled by the syntax filter. See the
documentation of
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax> for details.

The subclass B<may> override
L<__single_line_re()|/__single_line_re> and/or
L<__in_line_doc_re()|/__in_line_documentatio_re>. If it does
not, it gets a syntax like C itself, without single-line comments or
in-line documentation.

=head1 METHODS

This class adds the following methods:

=head2 __block_re

This method returns either nothing, two regular expressions, or a
regular expression with a single capture group and a reference to a hash
of regular expressions keyed on possible captures of the first return.

The first return value is used to detect the beginning of a block
comment. The second return value is used to detect the end of a block
comment. The hash provides for cases where multiple block comment
formats exist (e.g. Pascal).

This implementation returns

  (
    qr{ \A \s* / [*] }smx,
    qr{ [*] / }smx,
  )

=head2 __in_line_doc_re

This method returns either nothing, two regular expressions, or a
regular expression with a single capture group and a reference to a hash
of regular expressions keyed on possible captures of the first return.

The first return value is used to detect the beginning of in-line
documentation.  comment. The second return value is used to detect the
end of in-line documentation.  comment.  The hash provides for cases
where multiple in-line documentation formats exist.

If this regular expression is provided it is tried before block
comments.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having in-line documentation.

=head2 __single_line_re

This method returns a regular expression that matches a comment line, or
nothing if the syntax does not support single-line comments.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having single-line comments.

=head2 __single_line_doc_re

This method returns a regular expression that matches a single-line
in-line documentation line, or nothing if the syntax does not support
single-line in-line documentation.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having single-line in-line
documentation.

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
