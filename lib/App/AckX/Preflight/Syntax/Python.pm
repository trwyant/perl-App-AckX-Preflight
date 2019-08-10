package App::AckX::Preflight::Syntax::Python;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Syntax ();
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

    @ISA = qw{ App::AckX::Preflight::Syntax };

    $VERSION = '0.000_025';

    __PACKAGE__->__handles_type_mod( qw{ set python } );
}

sub __handles_syntax {
    return(
	SYNTAX_CODE,
	SYNTAX_COMMENT,
	SYNTAX_DOCUMENTATION,
	SYNTAX_METADATA,
    );
}

{
    my $classify;

    BEGIN {

	$classify = {
	    SYNTAX_CODE()		=> sub {
#		my ( $self, $attr ) = @_;
		my ( undef, $attr ) = @_;
		if ( m/ \A \s* \# /smx ) {
		    1 == $.
			and m/ python /smx
			and return SYNTAX_METADATA;
		    return SYNTAX_COMMENT;
		} elsif ( m/ \A \s* """ ( .+ """ \s* \z )? /smx ) {
		    my $kind = delete $attr->{was_def} ?
			SYNTAX_DOCUMENTATION : SYNTAX_COMMENT;
		    $1
			or $attr->{in} = $kind;
		    return $kind;
		}
		$attr->{was_def} = m/ \A \s* def \s+ /smx;
		return SYNTAX_CODE;
	    },
	    SYNTAX_COMMENT()		=> sub {
#		my ( $self, $attr ) = @_;
		my ( undef, $attr ) = @_;
		m/ """ \s* \z /smx
		    and $attr->{in} = SYNTAX_CODE;
		return SYNTAX_COMMENT;
	    },
	    SYNTAX_DOCUMENTATION()	=> sub {
#		my ( $self, $attr ) = @_;
		my ( undef, $attr ) = @_;
		m/ """ \s* \z /smx
		    and $attr->{in} = SYNTAX_CODE;
		return SYNTAX_DOCUMENTATION;
	    },
	};
    }

    sub __classify {
	my ( $self ) = @_;
	my $attr = $self->__my_attr();
	return $classify->{ $self->__my_attr()->{in} }->( $self, $attr );
    }
}

sub __init {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    $attr->{in} = SYNTAX_CODE;
    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Python - App::AckX::Preflight syntax filter for Python-like languages.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Python-like
syntax, returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment (i.e. comments)

=item data (non-POD stuff after __DATA__ and/or __END__)

=item documentation (i.e. POD)

=item metadata (shebang, C<#line>, C<__DATA__>, C<__END__>).

=back

In principal this syntax filter can be used for any syntax that consists
of code, single-line comments introduced by C<'#'>,
and in-line POD-style documentation. By default it applies to the
following file types:

=over

=item c<parrot>

=item C<perl>

=item C<perltest>

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

Copyright (C) 2018-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
