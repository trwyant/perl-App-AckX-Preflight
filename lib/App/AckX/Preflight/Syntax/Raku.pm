package App::AckX::Preflight::Syntax::Raku;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{ :syntax @CARP_NOT };

our $VERSION = '0.000_046';

__PACKAGE__->__handles_type_mod( qw{ set raku } );

my $open_bracket = qr/ [({[<\N{U+AB}] /smx;	# )}]

sub _close_bracket {
    my ( $brkt ) = @_;
    $brkt =~ tr/({[<\N{U+AB}/)}]>\N{U+BB}/;
    return $brkt;
}

sub __handles_syntax {
    return(
	SYNTAX_CODE,
	SYNTAX_COMMENT,
	# SYNTAX_DATA,	# TODO I think POD is also inline data but ...
	SYNTAX_DOCUMENTATION,
	SYNTAX_METADATA,
    );
}

sub __classify {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    state $classify = {
	SYNTAX_CODE()		=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;
	    if ( m/ \A \s* \# (?! [|=] ) /smx ) {
		1 == $.
		    and m/ raku /smx
		    and return SYNTAX_METADATA;
#		m/ \A \#line \s+ [0-9]+ /smx
#		    and return SYNTAX_METADATA;
		# Paren, bracket, brace, French quote
		if ( m/ \A \s* \# ` ( ( $open_bracket ) \g{-1}* ) /smx ) {
		    my $end = _close_bracket( $1 );
		    $end = qr/\Q$end\E/;
		    $_ =~ $end
			and return SYNTAX_COMMENT;
		    $attr->{block_comment_end} = $end;
		    $attr->{in} = SYNTAX_COMMENT;
		}
		return SYNTAX_COMMENT;
	    }
	    goto &_handle_possible_pod;
	},
	SYNTAX_COMMENT()	=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;
	    if ( $_ =~ $attr->{block_comment_end} ) {
		$attr->{in} = SYNTAX_CODE;
		delete $attr->{block_comment_end};
	    }
	    return SYNTAX_COMMENT;
	},
	# SYNTAX_DATA()		=> \&_handle_possible_pod,
	SYNTAX_DOCUMENTATION()	=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;
	    if ( defined $attr->{block_doc_end} &&
		index( $_, $attr->{block_doc_end} ) >= 0
	    ) {
		$attr->{in} = SYNTAX_CODE;
		delete $attr->{block_doc_end};
	    } elsif ( m/ \A = end \s+ pod \b /smx ) {
		$attr->{in} = SYNTAX_CODE;
	    }
	    return SYNTAX_DOCUMENTATION;
	},
    };
    return $classify->{ $attr->{in} }->( $self, $attr );
}

sub __init {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    $attr->{in} = SYNTAX_CODE;
    return;
}

# This co-routine MUST only be called if $attr->{in} is NOT
# 'documentation'.
sub _handle_possible_pod {
#   my ( $self, $attr ) = @_;
    my ( undef, $attr ) = @_;

    # Single-line declarator block.
    m/ \A \# [|=] \s /smx
	and return SYNTAX_DOCUMENTATION;

    # Multi-line declarator block
    if ( m/ \A \# [|=] ( $open_bracket ) /smx ) {
	$attr->{block_doc_end} = _close_bracket( $1 );
	$attr->{in} = SYNTAX_DOCUMENTATION;
	return SYNTAX_DOCUMENTATION;
    }

    m/ \A = begin \s+ pod \b /smx
	or return $attr->{in};

    $attr->{in} = SYNTAX_DOCUMENTATION;
    return SYNTAX_DOCUMENTATION;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Raku - App::AckX::Preflight syntax filter for Raku-like languages.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Raku/Perl6
file, returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment (both single-line and block comments are supported, though both are recognized only as the first element in a line)

=item metadata (currently only the shebang line)

=item documentation (i.e. POD, declarator blocks)

=back

The supported file type is C<raku>, which is not a built-in F<ack> file
type.

=head1 TODO

=head2 POD

This is covered, but the Raku docs say it starts with C<=begin pod> and
runs until C<=end pod>.

=head2 Data blocks

At one time these were going to be provided by POD. But I have no idea
what happened to them.

=head2 UTF-8

Raku requires UTF-8 source, but F<ack> just opens files with the default
encoding. Until this gets sorted out, things like French quotes will not
work correctly.

=head1 METHODS

This class is a subclass of
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>. It
overrides the following methods:

=head2 __handles_syntax

=head2 __classify

=head2 __init

=head1 SEE ALSO

<<< replace or remove boilerplate >>>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
