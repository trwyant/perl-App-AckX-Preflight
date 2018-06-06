package App::AckX::Preflight::Syntax::_nesting;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{
    :croak
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_018';

{
    my $classifier = {
	SYNTAX_CODE()	=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;
	    if ( $attr->{has_shebang} && 1 == $. && m/ \A \# ! /smx ) {
		return SYNTAX_METADATA;
	    } elsif ( $attr->{single_line_doc_re} && $_ =~
		$attr->{single_line_doc_re } ) {
		return SYNTAX_DOCUMENTATION;
	    } elsif ( $attr->{single_line_re} && $_ =~
		$attr->{single_line_re} ) {
		return SYNTAX_COMMENT;
	    } elsif ( $attr->{block_start} &&
		m/ \A \s* ( $attr->{block_start} ) /smx ) {
		if ( defined $attr->{block_doc_re} ) {
		    my $start = $1;
		    $attr->{in} = $start =~ $attr->{block_doc_re} ?
			SYNTAX_DOCUMENTATION :
			SYNTAX_COMMENT;
		} else {
		    $attr->{in} = SYNTAX_COMMENT;
		}
		$attr->{comment_depth} = 0;
		goto &_handle_comment;
	    } else {
		return SYNTAX_CODE;
	    }
	},
	SYNTAX_COMMENT()	=> \&_handle_comment,
	SYNTAX_DOCUMENTATION()	=> \&_handle_comment,
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
    my ( $block_start, $block_end ) = $self->__block_re();
    $attr->{in} = SYNTAX_CODE;
    $attr->{has_shebang}	= $self->__has_shebang();
    $attr->{single_line_re}	= $self->__single_line_re();
    $attr->{single_line_doc_re}	= $self->__single_line_doc_re();
    $attr->{block_start}	= $block_start;
    $attr->{block_end}		= $block_end;
    $attr->{block_doc_re}	= $self->__block_doc_re();
    return;
}

sub _handle_comment {
#   my ( $self, $attr ) = @_;
    my ( undef, $attr ) = @_;
    while ( m/ ( $attr->{block_start} ) | $attr->{block_end} /smxg ) {
	$attr->{comment_depth} += $1 ? 1 : -1;
    }
    0 < $attr->{comment_depth}
	and return $attr->{in};
    delete $attr->{comment_depth};
    my $was = $attr->{in};
    $attr->{in} = SYNTAX_CODE;
    return $was;
}

sub __has_shebang {
    return 1;
}

sub __single_line_re {
    return;
}

sub __single_line_doc_re {
    return;
}

sub __block_re {
    return;
}

sub __block_doc_re {
    return;
}


1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::_nesting - App::AckX::Preflight syntax filter for a syntax with nesting block comments.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This Perl class is intended to be subclassed to produce a
This L<PerlIO::via|PerlIO::via> I/O layer used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a syntax whose
comments nest. Specifically, we assume:

=over

=item A possible shebang line is the only metadata;

=item There is only one style of block comment;

=item The regular expression that matches the start of a block comment
also matches the start of block documentation.

=back

=head1 METHODS

This class overrides or adds the following parent methods:

=head2 __init

=head2 __classify

=head2 __has_shebang

This method returns a true value. It should be overridden to return a
false value if the syntax does not permit a shebang line.

=head2 __single_line_re

This static method returns a regular expression that matches a
single-line comment, or nothing if these are not supported by the
syntax.

This class implements a method that returns nothing.

=head2 __single_line_doc_re

This static method returns a regular expression that matches a
single-line documentation entry, or nothing if these are not supported
by the syntax.

This class implements a method that returns nothing.

=head2 __block_re

This static method returns two regular expressions, matching the start
and end of a block comment, or nothing if block comments are not
supported by the syntax. If block in-line documentation is supported,
the first regular expression should match the start of either comments
or documentation.

This class implements a method that returns nothing.

=head2 __block_doc_re

This static method returns a regular expression that matches the start
of block in-line documentation, or nothing if block in-line
documentation is not supported. If a regular expression is returned, it
is used to distinguish between comments and documentation.

This class implements a method that returns nothing.

=head1 ATTRIBUTES

This class has the following attributes:


=head1 SEE ALSO

<<< replace or remove boilerplate >>>

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
