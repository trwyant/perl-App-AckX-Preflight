package App::AckX::Preflight::Syntax::_cc_like;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{ :croak :ref :syntax @CARP_NOT };

our $VERSION = '0.000_046';

sub __handles_syntax {
    __die_hard( '__handles_syntax() must be overridden' );
}

{
    my $classifier = {	# Anticipating 'state'.
	SYNTAX_CODE()		=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;

	    my @match;
	    if ( 1 == $. && $attr->{shebang} && m/ \A \# ! /smx ) {
		return SYNTAX_METADATA;
	    } elsif ( $attr->{in_line_doc_start} and
		@match = $_ =~ $attr->{in_line_doc_start} ) {
		my $block_end = _get_block_end( $attr,
		    in_line_doc_end => @match );
		$_ =~ $block_end
		    and return SYNTAX_DOCUMENTATION;
		$attr->{_in_line_doc_end} = $block_end;
		$attr->{in} = SYNTAX_DOCUMENTATION;
	    } elsif ( $attr->{block_start} and
		@match = $_ =~ $attr->{block_start} ) {
		my $block_end = _get_block_end( $attr, block_end => @match );
		$_ =~ $block_end
		    and return SYNTAX_COMMENT;
		$attr->{_block_end} = $block_end;
		$attr->{in} = SYNTAX_COMMENT;
	    } elsif ( $attr->{block_meta_start} and
		@match = $_ =~ $attr->{block_meta_start} ) {
		my $block_meta_end = _get_block_end( $attr,
		    block_meta_end => @match );
		$_ =~ $block_meta_end
		    and return SYNTAX_METADATA;
		$attr->{_block_meta_end} = $block_meta_end;
		$attr->{in} = SYNTAX_METADATA;
	    } elsif ( $attr->{single_line_doc_re} and
		$_ =~ $attr->{single_line_doc_re} ) {
		if ( $attr->{comments_continue_doc} ) {
		    $attr->{in} = SYNTAX_DOCUMENTATION;
		    $attr->{_in_single_line_doc} = 1;
		}
		return SYNTAX_DOCUMENTATION;
	    } elsif ( $attr->{single_line_re} and
		$_ =~ $attr->{single_line_re} ) {
		return SYNTAX_COMMENT;
	    }
	    return $attr->{in};
	},
	SYNTAX_COMMENT()		=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;

	    if ( $_ =~ $attr->{_block_end} ) {
		my $was = $attr->{in};
		$attr->{in} = SYNTAX_CODE;
		delete $attr->{_block_end};
		# We have to hand-dispatch the line because although
		# the next line is code, the end of the block
		# comment is doc.
		return $was;
	    }

	    return $attr->{in};
	},
	SYNTAX_DOCUMENTATION()	=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;

	    if ( $attr->{_in_single_line_doc} ) {
		unless ( $_ =~ $attr->{single_line_re} ) {
		    $attr->{in} = SYNTAX_CODE;
		    delete $attr->{_in_single_line_doc};
		}
	    } elsif ( $_ =~ $attr->{_in_line_doc_end} ) {
		my $was = $attr->{in};
		$attr->{in} = SYNTAX_CODE;
		delete $attr->{_in_line_doc_end};
		# We have to hand-dispatch the line because although
		# the next line is code, the end of the block
		# comment is doc.
		return $was;
	    }

	    return $attr->{in};
	},
	SYNTAX_METADATA()		=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;

	    if ( $_ =~ $attr->{_block_meta_end} ) {
		my $was = $attr->{in};
		$attr->{in} = SYNTAX_CODE;
		delete $attr->{_block_meta_end};
		# We have to hand-dispatch the line because although
		# the next line is code, the end of the block
		# metadata is metadata.
		return $was;
	    }

	    return $attr->{in};
	},
    };

    sub __classify {
	my ( $self ) = @_;
	my $attr = $self->__my_attr();
	return $classifier->{ $attr->{in} }->( $self, $attr );
    }
}

sub __init {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    my $single_line_re = $self->_validate_single_line(
	'__single_line_re()', $self->__single_line_re() );
    my $single_line_doc_re = $self->_validate_single_line(
	'__single_line_doc_re()', $self->__single_line_doc_re() );
    my $single_line_meta_re = $self->_validate_single_line(
	'__single_line_meta_re()', $self->__single_line_meta_re() );
    my ( $block_start, $block_end ) = $self->_validate_block(
	'__block_re()', $self->__block_re() );
    my ( $in_line_doc_start, $in_line_doc_end ) = $self->_validate_block(
	'__in_line_doc_re()', $self->__in_line_doc_re() );
    my ( $block_meta_start, $block_meta_end ) = $self->_validate_block(
	'__block_meta_re()', $self->__block_meta_re() );
    $attr->{in}			= SYNTAX_CODE;
    $attr->{block_start}	= $block_start;
    $attr->{block_end}		= $block_end;
    $attr->{comments_continue_doc}	= $self->__comments_continue_doc();
    $attr->{shebang}		= $self->__has_shebang();
    $attr->{in_line_doc_start}	= $in_line_doc_start;
    $attr->{in_line_doc_end}	= $in_line_doc_end;
    $attr->{block_meta_start}	= $block_meta_start;
    $attr->{block_meta_end}	= $block_meta_end;
    $attr->{single_line_re}	= $single_line_re;
    $attr->{single_line_doc_re}	= $single_line_doc_re;
    $attr->{single_line_meta_re} = $single_line_meta_re;
    return;
}

sub _get_block_end {
    my ( $attr, $kind, @arg ) = @_;
    return $attr->{$kind}->( @arg ) || __die_hard(
	sprintf q<No block end corresponds to '%s'>,
	substr $_, $-[0], $+[0] - $-[0] );
}

# TODO if we can count on Perl 5.9.5 we can return qr{(*FAIL)}smx rather
# than nothing, and not have to check if the regexp exists.
sub _validate_block {
    my ( undef, $kind, $start, $end ) = @_;
    defined $start
	or return;
    REGEXP_REF eq ref $start
	or __die_hard( "$kind start must be Regexp ref or undef" );
    CODE_REF eq ref $end
	or __die_hard( "$kind end must be CODE ref" );
    return ( $start, $end );
}

# TODO if we can count on Perl 5.9.5 we can return qr{(*FAIL)}smx rather
# than nothing, and not have to check if the regexp exists.
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
	sub { return qr{ [*] / }smx },
    );
}

sub __comments_continue_doc {
    return;
}

sub __in_line_doc_re {
    return;
}

sub __block_meta_re {
    return;
}

sub __has_shebang {
    return;
}

sub __single_line_doc_re {
    return;
}

sub __single_line_meta_re {
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

The subclass B<may> override any of the other subroutines documented
below if they are relevant to the syntax it is trying to parse.

=head1 METHODS

This class is a subclass of
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>. It adds or
overrides the following methods:

=head2 __classify

=head2 __init

=head2 __block_re

This method returns one of the following:

=over

=item nothing;

=item a regular expression and a reference to code that accepts anything
captured by the regular expression as its arguments and returns a
regular expression.

=back

The first return value is used to detect the beginning of a block
comment. The second return value is used to detect the end of a block
comment. If nothing is returned, this syntax element will not be
detected.

This implementation returns

  (
    qr{ \A \s* / [*] }smx,
    qr{ [*] / }smx,
  )

=head2 __comments_continue_doc

This method returns a false value. It should be overridden to return a
true value if and only if:

=over

=item - Single-line documentation is supported;

=item - Single-line comments continue single-line documentation (e.g.  Haskell).

=back

=head2 __has_shebang

This method returns a false value. It should be overridden to return a
true value if the syntax permits a shebang line.

=head2 __in_line_doc_re

This method returns the same things as L<__block_re()|/__block_re>,
above.

The first return value is used to detect the beginning of in-line
documentation. The second return value is used to detect the end of
in-line documentation.

If this regular expression is provided it is tried before block
comments.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having in-line documentation.

=head2 __block_meta_re

This method returns the same things as L<__block_re()|/__block_re>,
above.

The first return value is used to detect the beginning of block
metadata. The second return value is used to detect the end of block
metadata.

If this regular expression is provided it is tried after block
comments.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having block metadata.

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

=head2 __single_line_meta_re

This method returns a regular expression that matches a single line of
metadata, or nothing if the syntax does not support single-line
metadata.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having single-line metadata.

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
