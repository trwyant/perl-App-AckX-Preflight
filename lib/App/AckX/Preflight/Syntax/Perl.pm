package App::AckX::Preflight::Syntax::Perl;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{ :syntax @CARP_NOT };

our $VERSION = '0.000_043';

__PACKAGE__->__handles_type_mod( qw{ set parrot perl perltest } );

sub __handles_syntax {
    return(
	SYNTAX_CODE,
	SYNTAX_COMMENT,
	SYNTAX_DATA,
	SYNTAX_DOCUMENTATION,
	SYNTAX_METADATA,
    );
}

{
    my $is_data = { map {; "__${_}__\n" => 1 } qw{ DATA END } };

    my $classify = {
	SYNTAX_CODE()		=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;
	    if ( m/ \A \s* \# /smx ) {
		1 == $.
		    and m/ perl /smx
		    and return SYNTAX_METADATA;
		m/ \A \#line \s+ [0-9]+ /smx
		    and return SYNTAX_METADATA;
		return SYNTAX_COMMENT;
	    }
	    if ( $is_data->{$_} ) {
		$attr->{in} = SYNTAX_DATA;
		return SYNTAX_METADATA;
	    }
	    goto &_handle_possible_pod;
	},
	SYNTAX_DATA()		=> \&_handle_possible_pod,
	SYNTAX_DOCUMENTATION()	=> sub {
#	    my ( $self, $attr ) = @_;
	    my ( undef, $attr ) = @_;
	    m/ \A = cut \b /smx
		and $attr->{in} = delete $attr->{cut};
	    return SYNTAX_DOCUMENTATION;
	},
    };

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

# This co-routine MUST only be called if $attr->{in} is NOT
# 'documentation'.
sub _handle_possible_pod {
#   my ( $self, $attr ) = @_;
    my ( undef, $attr ) = @_;
    if ( m/ \A = ( cut \b | [A-Za-z] ) /smx ) {
	'cut' eq $1
	    and return SYNTAX_DOCUMENTATION;
	$attr->{cut} = $attr->{in};
	$attr->{in} = SYNTAX_DOCUMENTATION;
    }
    return $attr->{in};
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Perl - App::AckX::Preflight syntax filter for Perl-like languages.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Perl-like
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
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
