package App::AckX::Preflight::Syntax::Crystal;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{ :croak :syntax @CARP_NOT };

our $VERSION = '0.000_044';

sub __handles_syntax {
    return(
	SYNTAX_CODE,
	SYNTAX_COMMENT,
	SYNTAX_DOCUMENTATION,
	SYNTAX_METADATA,
    );
}

__PACKAGE__->__handles_type_mod( qw{ set crystal } );

sub __classify {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    return ( $attr->{in} = $self->_classification_engine() );
}

# This is a separate subroutine just to simplify maintaining the
# type of the previous lime.
sub _classification_engine {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();

    if ( $attr->{end} ) {
	$attr->{end}->()
	    and delete $attr->{end};
	return $attr->{in};
    }

    if ( $. == 1 && m/\A#!.*crystal/ ) {
	return SYNTAX_METADATA;
    } elsif ( m/ \A \s* \# /smx ) {
	state $preserve = { map { $_ => 1 } SYNTAX_COMMENT,
	    SYNTAX_DOCUMENTATION };
	$preserve->{$attr->{in}}
	    and return $attr->{in};
	my $fh = $self->__get_peek_handle();
	local $_ = undef;	# while (<>) does not localize $_
	while ( <$fh> ) {
	    m/ \A \s* \# /smx
		and next;
	    return m/ \A \s* \z /smx ? SYNTAX_COMMENT :
	    SYNTAX_DOCUMENTATION;
	}
	return SYNTAX_COMMENT;
    } elsif ( m/ \A \s* annotation \b /smx ) {
	$attr->{end} = sub { return m/ \A \s* end \b /smx };
	return SYNTAX_METADATA;
    } elsif ( m/ \A \@ \[ /smx ) {
	m/ [)] []] /smx
	    or $attr->{end} = sub { return m/ [)] []] /smx };
	return SYNTAX_METADATA;
    } else {
	return SYNTAX_CODE;
    }
}

sub __init {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    $attr->{in} = SYNTAX_CODE;	# Prime the pump.
    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Crystal - App::AckX::Preflight syntax filter for the Crystal language.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process the Crystal
language syntax, returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment (C<#...> followed by blank line)

=item documentation (C<#...> followed by non-blank line)

=item metadata (shebang, annotations)

=back

=head1 METHODS

This class is a subclass of
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>. It adds or
overrides the following methods:

=head2 __classify

=head2 __handles_syntax

=head2 __init

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

Copyright (C) 2022-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
