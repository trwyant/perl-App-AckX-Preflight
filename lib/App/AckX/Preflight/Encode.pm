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

our $VERSION = '0.000_046';

use constant ENCODING_LAYER => qr{ \A encoding\( }smx;

use constant ITEM_ENCODING	=> 0;
use constant ITEM_FILTER_TYPE	=> 1;
use constant ITEM_FILTER_ARG	=> 2;

sub _get_file_encoding {
    my ( undef, $config, $file ) = @_;

    return $config->{_encoding}->( $file ) // undef;
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
    my %cfg = (
	is	=> {},
	match	=> [],
	type	=> [],
    );
    foreach my $item ( @{ $config->{encoding} || [] } ) {
	state $transform = {
	    is		=> \&_config_encoding_is,
	    match	=> \&_config_encoding_match,
	    type	=> \&_config_encoding_type,
	};
	my $code = $transform->{ $item->[1] }
	    or __die_hard( "Invalid encoding filter '$item->[1]'" );
	$code->( \%cfg, $item );
    }
    $config->{_encoding} = sub {
	my ( $file ) = @_;
	local $_ = $file->name();
	defined( $cfg{is}{$_} )
	    and return $cfg{is}{$_};
	foreach my $item ( @{ $cfg{match} } ) {
	    $_ =~ $item->[ITEM_FILTER_ARG]
		and return $item->[ITEM_ENCODING];
	}
	foreach my $item ( @{ $cfg{type} } ) {
	    $App::Ack::mappings{$item->[ITEM_FILTER_ARG]}
		or __die(
		"Invalid --encoding file type '$item->[ITEM_FILTER_ARG]'" );
	    foreach my $filter ( @{
		$App::Ack::mappings{$item->[ITEM_FILTER_ARG]} } ) {
		$filter->filter( $file )
		    and return $item->[ITEM_ENCODING];
	    }
	}
	return;
    };
    return;
}

sub _config_encoding_is {
    my ( $config, $item ) = @_;
    $config->{is}{$item->[ITEM_FILTER_ARG]} = $item->[ITEM_ENCODING];
    return;
}

sub _config_encoding_match {
    my ( $config, $item ) = @_;
    $item->[ITEM_FILTER_ARG] = qr/$item->[ITEM_FILTER_ARG]/;
    push @{ $config->{match} }, $item;
    return;
}

sub _config_encoding_type {
    my ( $config, $item ) = @_;
    push @{ $config->{type} }, $item;
    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Encode - <<< replace boilerplate >>>

=head1 SYNOPSIS

<<< replace boilerplate >>>

=head1 DESCRIPTION

<<< replace boilerplate >>>

=head1 METHODS

This class supports the following public methods:

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
