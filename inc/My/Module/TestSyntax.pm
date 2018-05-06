package My::Module::TestSyntax;

use 5.008008;

use strict;
use warnings;

use Carp;
use Exporter qw{ import };
use Scalar::Util qw{ blessed openhandle };

our $VERSION = '0.000_007';

our @EXPORT = qw{ slurp };

sub slurp {
    my ( $file ) = @_;
    my $caller = caller;
    my $syntax = $caller->SYNTAX_FILTER();
    my $fh;
    if ( blessed( $file ) ) {
	$fh = $file->open()
	    or die "@{[ ref $file ]}->open() failed: $!\n";
    } elsif ( openhandle( $file ) ) {
	$fh = $file;
    } else {
	open $fh, "<:via($syntax)", $file
	    or die "Failed to open $file: $!\n";
    }
    my $rslt;
    while ( <$fh> ) {
	s/ \s+ \z //smx;
	if ( '' eq $_ ) {
	    $rslt .= sprintf "%4d:\n", $.;
	} else {
	    $rslt .= sprintf "%4d: %s\n", $., $_;
	}
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

My::Module::TestSyntax - <<< replace boilerplate >>>

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
