package App::AckX::Preflight::Syntax::Lisp;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{
    :croak
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_014';

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT, SYNTAX_DOCUMENTATION,
	SYNTAX_METADATA );
}

__PACKAGE__->__handles_type_mod( qw{ set clojure elisp lisp scheme } );

{
    my $classifier = {
	SYNTAX_CODE()	=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;
	    if ( 1 == $. && m/ \A \# ! /smx ) {
		return SYNTAX_METADATA;
	    } elsif ( m/ \A \s* ( ;+ ) /smx ) {
		return 2 < length $1 ?
		    SYNTAX_DOCUMENTATION :
		    SYNTAX_COMMENT;
	    } elsif ( m/ \A \s* \# \| /smx ) {
		$attr->{in} = SYNTAX_COMMENT;
		$attr->{comment_depth} = 0;
		goto &_handle_comment;
	    } else {
		return SYNTAX_CODE;
	    }
	},
	SYNTAX_COMMENT()	=> \&_handle_comment,
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
    $attr->{in} = SYNTAX_CODE;
    return;
}

{
    my $adjust = {
	'#|'	=> 1,
	'|#'	=> -1,
    };

    sub _handle_comment {
#	my ( $self, $attr ) = @_;
	my ( undef, $attr ) = @_;
	while ( m/ ( \# \| | \| \# ) /smxg ) {
	    $attr->{comment_depth} += $adjust->{$1};
	}
	if ( 0 >= $attr->{comment_depth} ) {
	    delete $attr->{comment_depth};
	    $attr->{in} = SYNTAX_CODE;
	}
	return SYNTAX_COMMENT;
    }
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Lisp - App::AckX::Preflight syntax filter for Lisp.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Lisp file,
returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment

=item documentation (i.e. C<;;;>-lines)

=item metadata (shebang line)

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
