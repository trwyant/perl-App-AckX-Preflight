
use 5.008008;

use strict;
use warnings;

use blib;

use App::AckX::Preflight;
use Getopt::Long 2.33 qw{ :config no_auto_version pass_through };
use Pod::Usage;

our $VERSION = '0.000_043';

my %opt;

GetOptions( \%opt,
    qw{ exec! output=s verbose! },
    help => sub { pod2usage( { -verbose => 2 } ) },
    version	=> sub {
	local @ARGV = qw{ --version };
	App::AckX::Preflight->run()
    },
) and @ARGV or pod2usage( { -verbose => 0 } );

my $ackxp = App::AckX::Preflight->new(
    exec	=> $opt{exec},
    output	=> $opt{output},
    verbose	=> $opt{verbose},
);

$ackxp->__execute( $^X, @ARGV );

__END__

=head1 TITLE

execute.PL - Helper script for t/execute.t

=head1 SYNOPSIS

 execute.PL
 execute.PL -help
 execute.PL -version

=head1 OPTIONS

=head2 --exec

This Boolean option sets the C<exec> argument to
L<App::AckX::Preflight|App::AckX::Preflight>->C<new()>.

=head2 -help

This option displays the documentation for this script. The script then
exits.

=head2 -version

This option displays the version of this script. The script then exits.

=head1 DETAILS

This Perl script simply calls

 my $ackxp = App::AckX::Preflight->new( exec => $opt{exec} );
 $ackxp->__execute( $^X, @ARGV );

The idea is that the test script runs this script in back ticks and
judges whether C<__execute()> is working by comparing the output of that
operation to what it is expecting.

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
