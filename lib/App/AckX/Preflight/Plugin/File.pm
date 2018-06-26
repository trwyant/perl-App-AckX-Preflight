package App::AckX::Preflight::Plugin::File;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Plugin;
use App::AckX::Preflight::Util ();

our @ISA;

our $VERSION;

BEGIN {

    App::AckX::Preflight::Util->import(
	qw{
	    :all
	}
    );
    @ISA = qw{ App::AckX::Preflight::Plugin };

    $VERSION = '0.000_018';
}

sub __options {
    return( qw{ file=s } );
}

sub __peek_opt {
    return( qw{ match=s } );
}

sub __process {
    my ( undef, undef, $opt ) = @_;

    # Unless we actually have a --file option, we have nothing to do.
    defined $opt->{file}
	or return;

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
	push @pattern, '' eq $_ ? '(?#)' :
	    $opt->{literal} ? quotemeta $_ : $_;
    }

    close $fh;

    # Die if there are no patterns.
    @pattern
	or __die( "No patterns found in $opt->{file}" );


    # If we got more than one pattern
    if ( 1 < @pattern ) {

	# The Regex we need to build requires 5.009005, really.
	'5.009005' gt $]
	    and __die(
	    "Perl $] does not support multiple patterns in a file" );

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

Each line of the file represents a pattern. An empty file results in an
exception. An empty pattern matches the empty string, and therefore any
line in the file.

Files containing more than one pattern can only be processed when
running under at least Perl 5.9.5. An attempt to use such a file under
an earlier Perl will result in an exception.

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
