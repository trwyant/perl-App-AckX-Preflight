package App::AckX::Preflight::Encode;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{
    __load_ack_config
    @CARP_NOT
};

our $VERSION = '0.000_044';

use constant ENCODING_LAYER => qr{ \A encoding\( }smx;

sub __get_type_encoding {
    my ( undef, $config, $file ) = @_;	# Invocant unused

    state $ack_config_loaded = __load_ack_config();	# Only call once

    foreach my $type ( keys %App::Ack::mappings ) {
	foreach my $filter ( @{ $App::Ack::mappings{$type} || [] } ) {
	    $filter->filter( $file )
		or next;
	    return $config->{encode_type}{$type};
	}
    }

    return undef;	## no critic (ProhibitExplicitReturnUndef)
}

sub __setup {
    my ( $class, $config, $fh, $file ) = @_;	# Invocant unused

    my $encoding = $config->{encode_file}{$file->name()} //
	$class->__get_type_encoding( $config, $file ) //
	return;


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

    # Insert the correct encoding into the PerlIO stack.
    binmode $fh, ":encoding($encoding)"
	or __die( sprintf 'Failed to set encoding %s on file %s: %s',
	$encoding, $file->name(), $!,
    );

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
