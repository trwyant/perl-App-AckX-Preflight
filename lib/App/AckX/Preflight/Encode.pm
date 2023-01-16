package App::AckX::Preflight::Encode;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{
    :os
    __load_ack_config
    EMPTY_STRING
    @CARP_NOT
};

our $VERSION = '0.000_047';

use constant ENCODING_LAYER => qr{ \A encoding\( }smx;

use constant ITEM_ENCODING	=> 1;
use constant ITEM_FILTER_ARG	=> 0;

sub _get_file_encoding {
    my ( undef, $config, $file ) = @_;
    my $cfg = $config->{encoding};

    ### return $config->{_encoding}->( $file ) // undef;

    my $path = $file->name();

    if ( defined( my $encoding = $cfg->{is}{$path} ) ) {
	return $encoding;
    }

    if ( my ( $ext ) = $path =~ m/ [.] ( [^.]+ ) \z /smx ) {
	if ( defined( my $encoding = $cfg->{ext}{$ext} ) ) {
	    return $encoding;
	}
    }

    foreach my $item ( @{ $cfg->{match} } ) {
	$path =~ $item->[ITEM_FILTER_ARG]
	    and return $item->[ITEM_ENCODING];
    }

    foreach my $type ( keys %{ $cfg->{type} } ) {
	foreach my $filter ( @{ $App::Ack::mappings{$type} } ) {
	    $filter->filter( $file )
		and return $cfg->{type}{$type};
	}
    }

    return undef;	## no critic (ProhibitExplicitReturnUndef)
}

sub __post_open {
    my ( $class, $config, $fh, $file ) = @_;	# Invocant unused

    # NOTE that the only known way $fh can be undefined is during
    # testing.
    $fh
	or return;

    # Check to see if we're already on the PerlIO stack. If so, just
    # return. The original open() is idempotent, and ack makes use of
    # this, so we have to be idempotent also.
    foreach my $layer ( PerlIO::get_layers( $fh ) ) {
	$layer =~ ENCODING_LAYER
	    and return;
    }

    my $encoding = $class->_get_file_encoding( $config, $file )
	// return;
    $encoding eq EMPTY_STRING
	and return;

    return "encoding($encoding)";
}

sub __setup {
    my ( undef, $config ) = @_;

    foreach my $item ( @{ $config->{match} } ) {
	$item->[ITEM_FILTER_ARG] = qr/$item->[ITEM_FILTER_ARG]/;
    }

    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Encode - Set the encoding of an input file.

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This module supplies the encoding layer (if any) for a file.

=head1 METHODS

This class supports no public methods over and above those needed to
supply an optional C<:encoding(...)> layer to the
L<App::AckX::Preflight|App::AckX::Preflight> system.

=head1 ATTRIBUTES

This class has the following attributes:


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

Copyright (C) 2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
