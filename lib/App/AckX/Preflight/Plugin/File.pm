package App::AckX::Preflight::Plugin::File;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Plugin };

use App::AckX::Preflight::Util qw{ :all };

our $VERSION = '0.000_048';

sub __options {
    return( qw{ file=s file-extended! } );
}

sub __peek_opt {
    return( qw{ match=s } );
}

sub __process {
    my ( undef, undef, $opt ) = @_;

    # We can't have --match if we have --file, since --file is
    # implemented using --match.
    defined $opt->{match}
	and __err_exclusive( qw{ file match } );

    # We need --literal if it is there.
    __getopt( $opt, qw{ literal|Q! } );

    # Read the file, or die.
    my $fh = __open_for_read( $opt->{file} );
    my @pattern;

    # Find any patterns in the file.
    while ( <$fh> ) {
	chomp;
	if ( $opt->{ 'file-extended' } ) {
	    '' eq $_
		and next;
	    m/ \A \s* \# /smx
		and next;
	}
	push @pattern, '' eq $_ ? '(?#)' :
	    $opt->{literal} ? quotemeta $_ : $_;
    }

    close $fh;

    # Die if there are no patterns.
    @pattern
	or __die( "No patterns found in $opt->{file}" );

    # If we got more than one pattern
    if ( 1 < @pattern ) {

	# Enclose the individual patterns in (?: ... ) unless it
	# looks like they are already parenthesized.
	@pattern = map {
	    m/ \A [(] .* [)] \z /smx ? $_ :  "(?:$_)" } @pattern;

	# Manufacture a --match, and inject it into the arguments.
	local $" = '|';
	unshift @ARGV, '--match', "(?|@pattern)";

    # If there is not more than one pattern
    } else {

	# Just inject it back into the arguments.
	unshift @ARGV, '--match', @pattern;

    }

    return;
}

sub __wants_to_run {
    my ( undef, $opt ) = @_;
    return defined $opt->{file};
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
C<--file> option is incompatible with the C<--match> option. If the
C<--literal> option is used (or its synonym C<-Q>), the patterns are
taken literally -- that is, metacharacters are escaped.

By default, each line of the file represents a pattern. An empty file
results in an exception. An empty pattern matches the empty string, and
therefore any line in the file.

If C<--file-extended> is asserted, the file syntax is extended to ignore
empty lines and lines whose first non-blank character is C<'#'>.
Otherwise all lines are considered to be patterns, like F<grep>.

Multiple patterns are joined via a branch reset; that is, something like
C<(?!pattern_1|pattern_2...)>. Each pattern is enclosed in C<(?:...)> to
prevent embedded alternations from being misinterpreted, unless the
pattern itself starts with C<'('> and ends with C<')'>.  It is the
responsibility of the author of the file to ensure that these
manipulations of the file's contents result in a valid regular
expression that has the desired functionality. I<Caveat coder.>

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

Copyright (C) 2018-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
