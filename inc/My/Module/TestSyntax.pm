package My::Module::TestSyntax;

use 5.010001;

use strict;
use warnings;

use Carp;
use Exporter qw{ import };
use Scalar::Util qw{ blessed openhandle };

our $VERSION = '0.000_044';

our @EXPORT = qw{
    slurp

    TEXT_FILE
    TEXT_CONTENT
};

use constant TEXT_FILE	=> 't/data/text_file.txt';

use constant TEXT_CONTENT	=> <<'EOD';
   1: There was a young lady named Bright,
   2: Who could travel much faster than light.
   3:     She set out one day
   4:     In a relative way
   5: And returned the previous night.
EOD

sub slurp {
    my ( $file, $opt ) = @_;
    $opt ||= {};
    my $fh;
    if ( blessed( $file ) ) {
	$fh = $file->open()
	    or die "@{[ ref $file ]}->open() failed: $!\n";
    } elsif ( openhandle( $file ) ) {
	$fh = $file;
    } else {
	my $caller = caller;
	my $syntax = $caller->SYNTAX_FILTER();
	open $fh, "<:via($syntax)", $file
	    or croak "Failed to open $file: $!\n";
    }
    my $rslt;
    while ( <$fh> ) {
	s/ \s+ \z //smx;
	my $leader = $opt->{tell} ?
	    sprintf '%4d %6d:', $., tell $fh :
	    sprintf '%4d:', $.;
	$rslt .= $_ eq '' ? "$leader\n" : "$leader $_\n";
    }
    if ( blessed( $file ) ) {
	$file->close();
    } else {
	close $fh;
    }
    return $rslt;
}

1;

__END__

=head1 NAME

My::Module::TestSyntax - Test syntax filters

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::TestSyntax;
 
 print slurp( $file_name );

=head1 DESCRIPTION

This Perl module contains support procedures for testing syntax filters.
It is B<private> to the C<App-AckX-Preflight> distribution, and may be
altered or retracted without notice. Documentation is a convenience of
the author, not a commitment to the user. Void where prohibited.

=head1 SUBROUTINES

This module exports the following subroutines:

=head2 slurp

 print slurp( $file_name, \%options );

This subroutine reads the given file, and returns its contents with line
numbers prefixe.

The \%option hash is itself optional. The only supported key is

=over

=item * tell - adds the file position B<after> the read to the output.

=back

=head1 MANIFEST CONSTANTS

This module exports the following manifest constants:

=head2 TEXT_FILE

This is the path to a plain text file used for testing. In fact, it is
F<t/data/text_file.txt>.

=head2 TEXT_CONTENT

This is the content of TEXT_FILE, after having been run through the
L<slurp()|/slurp> subroutine with default options.

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax> and
friends.

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
