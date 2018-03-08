package App::AckX::Preflight::Plugin::File;

use 5.008008;

use strict;
use warnings;

use Carp;

our $VERSION = '0.000_01';

sub __options {
    return( qw{ file=s match=s } );
}

sub __process {
    my ( $preflight, $opt ) = @_;

    # If we actually got a --file option
    if ( defined $opt->{file} ) {

	# We can't have --match if we have --file, since --file is
	# implemented using --match.
	defined $opt->{match}
	    and $preflight->die(
	    'Options --file and --match are mutually exclusive.' );

	# Read the file, or die.
	open my $fh, '<:encoding(utf-8)', $opt->{file}	## no critic (RequireBriefOpen)
	    or $preflight->die(
	    "Unable to open $opt->{file} for input: $!" );
	my @pattern;

	# Find any patterns in the file.
	while ( <$fh> ) {
	    m/ \S /smx
		and not m/ \A \s* [#] /smx
		or next;
	    chomp;
	    push @pattern, $_;
	}

	close $fh;

	# Die if there are no patterns.
	@pattern
	    or $preflight->die( "No patterns found in $opt->{file}" );

	# If we got more than one pattern
	if ( 1 < @pattern ) {

	    # The Regex we need to build requires 5.009005, really.
	    '5.010' gt $]
		and $preflight->die(
		"Perl $] does not support multiple patterns in a file" );

	    # Enclose the individual patterns in (?: ... ) unless it
	    # looks like they already are.
	    @pattern = map {
		m/ \A [(] [?] [[:lower:]]* : /smx ? $_ :  "(?:$_)" } @pattern;

	    # Manufacture a --match, and inject it into the arguments.
	    local $" = '|';
	    unshift @ARGV, '--match', "(?|@pattern)";

	# If there is not more than one pattern
	} else {

	    # Just inject it back into the arguments.
	    unshift @ARGV, '--match', @pattern;

	}

    # Else if we got a --match option
    } elsif ( defined $opt->{match} ) {

	# Inject it back into the arguments.
	unshift @ARGV, '--match', $opt->{match};

    }

    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::File - Provide --file for ackxp

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to load match patterns from a file.

In order to get this functionality, the user must specify the C<--file>
command line option, giving as its value the name of the file. The
C<--file> option is incompatible with the C<--match> option.

Each line of the file which contains non-white-space characters and
whose first such character is not a C<'#'> represents a pattern. Each
file must contain at least one pattern.

Files containing more than one pattern can only be processed when
running under at least Perl 5.10.0. An attempt to use such a file under
an earlier Perl will result in an exception.

Multiple patterns are joined via a branch reset; that is, something like
C<(?!pattern_1|pattern_2...)>. Each pattern is enclosed in C<(?:...)> to
prevent embedded alternations from being misinterpreted, unless the
pattern itself starts with C<'(?:'>.  It is the responsibility of the
author of the file to ensure that these manipulations of the file's
contents result in a valid regular expression that has the desired
functionality. I<Caveat coder.>

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
