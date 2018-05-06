package App::AckX::Preflight::Plugin::Syntax;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Syntax;
use Carp;
use List::Util 1.45 ();

use parent qw{ App::AckX::Preflight::Plugin };

our $VERSION = '0.000_007';

sub __options {
    return( qw{ syntax=s@ } );
}

sub __normalize_options {
    my ( undef, $opt ) = @_;

    if ( $opt->{syntax} ) {
	@{ $opt->{syntax} } = List::Util::uniqstr(
	    map { split qr{ \s* [:;,] \s* }smx } @{ $opt->{syntax} } );
    }

    return;
}

sub __process {
    my ( undef, $aaxp, $opt ) = @_;
    $opt->{syntax}
	and @{ $opt->{syntax} }
	or return;

    # Validate the arguments to -syntax. All such must be processed by
    # at least one plugin.
    {
	my %syntax = map { $_ => 1 } @{ $opt->{syntax} };

	foreach my $plugin ( App::AckX::Preflight::Syntax->__plugins() ) {
	    foreach my $type ( $plugin->__handles_syntax() ) {
		delete $syntax{$type};
	    }
	}

	local $" = ', ';
	keys %syntax
	    and croak "Unsupported syntax types: @{[ sort keys %syntax ]}";
    }

    {
	my @want_syntax = sort @{ $opt->{syntax} };
	local $" = ':';
	$aaxp->__inject(
	    "-MApp::AckX::Preflight::Syntax=-syntax=@want_syntax" );
    }

    return;

}


1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Syntax - <<< replace boilerplate >>>

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
