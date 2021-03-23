package My::Module::Preflight;

use 5.008008;

use strict;
use warnings;

use Carp;

our $VERSION = '0.000_034';

use App::AckX::Preflight;

our @ISA = qw{ App::AckX::Preflight };

sub __execute {
    my ( undef, @arg ) = @_;
    return @arg;
}

1;

__END__

=head1 NAME

My::Module::Preflight - Subclass of App::AckX::Preflight for testing

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Preflight;
 My::Module::Preflight->run();

=head1 DESCRIPTION

This Perl module is private to the F<App-AckX-Preflight> distribution,
and may be changed or retracted without notice. Documentation is for the
benefit of the author only.

This Perl module subclasses
L<App::AckX::Preflight|App::AckX::Preflight>, overriding behavior as
convenient for testing.

=head1 METHODS

The following possibly-private (or at least package-private) methods are
overridden. There is nothing to see here. Move along. Move along.

=head2 __execute

Instead of executing a command, this override just returns it.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
