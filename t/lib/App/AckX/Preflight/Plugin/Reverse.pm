package App::AckX::Preflight::Plugin::Reverse;

use 5.008008;

use strict;
use warnings;

use Carp;

our $VERSION = '0.000_001';

sub __options {
    return( qw{ reverse! } );
}

sub __process {
    my ( $preflight, $opt ) = @_;
    $opt->{reverse}
	and @ARGV = reverse @ARGV;
    return;
}


1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Reverse - Reverse arguments

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This Perl module looks for the C<-reverse> option in C<@ARGV>. If it
finds it asserted, C<@ARGV> is reversed. If it is unspecified, or
specified as C<-noreverse>, nothing happens. Either way, the C<-reverse>
option specificaiton is removed from C<@ARGV>.

=head1 SEE ALSO

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
