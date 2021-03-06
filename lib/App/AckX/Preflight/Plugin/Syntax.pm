package App::AckX::Preflight::Plugin::Syntax;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Plugin;
use App::AckX::Preflight::Syntax ();
use App::AckX::Preflight::Util ();

our @ISA;

our $VERSION;

BEGIN {
    App::AckX::Preflight::Util->import(
	qw{
	    IS_SINGLE_FILE
	    @CARP_NOT
	}
    );

    App::AckX::Preflight::Syntax->import( qw{
	__normalize_options
	} );

    @ISA = qw{ App::AckX::Preflight::Plugin };

    $VERSION = '0.000_037';
}

sub __options {
    return( qw{ syntax=s@ syntax-match! syntax-type! syntax-wc!
	syntax-wc-only! } );
}

sub __peek_opt {
    return( qw{ match=s } );
}

sub __process {
    my ( undef, $aaxp, $opt ) = @_;
    $opt->{syntax}
	and @{ $opt->{syntax} }
	or $opt->{'syntax-type'}
	or $opt->{'syntax-wc'}
	or $opt->{'syntax-wc-only'}
	or return;

    $opt->{'syntax-wc'} ||= $opt->{'syntax-wc-only'};

    my @arg = App::AckX::Preflight::Syntax->__get_syntax_opt( \@ARGV, $opt );

    if ( $opt->{'syntax-match'} && (
	    $opt->{'syntax-type'} || $opt->{'syntax-wc'} ) ) {
	$opt->{match}
	    or splice @ARGV, 0, 0, qw{ --match (?) };
    }

    if ( IS_SINGLE_FILE ) {
	App::AckX::Preflight::Syntax->__hot_patch();
    } else {
	local $" = ',';
	$aaxp->__inject(
	    "-MApp::AckX::Preflight::Syntax=@arg" );
    }

    return;

}

1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Syntax - Provide --syntax for ackxp

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to restrict the search to lines of a file that match one or more
syntax types which may (or may not) be defined for that file's file
type.

This plug-in recognizes and processes the following options:

=head2 --syntax

This specifies the syntax types which are to be searched. It can take
one or more of the following values:

=over

=item code

This is probably self-explanatory.

=item comment

This is also probably self-explanatory. In file types with C-style
comments, only full-line comments will appear here.

=item data

This is intended to represent inlined data. For Perl it would represent
C<__DATA__> or C<__END__>. Here documents would not normally count as
data.

=item documentation

This is structured inline documentation. For Perl it would be POD. For
Java it would be Javadoc, which would B<not> also be considered a
comment, even though functionally that is exactly what it is.

=item other

This is a catch-all category; you will have to consult the documentation
for the individual syntax filters to see what (if anything) gets put
into this category.

=back

Values can be abbreviated, as long as the abbreviation is unique.

These syntax types are implemented in subclasses of
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>. These
B<should> adhere to the above-defined types. Additional types might be
implemented, but the implementor is urged to think long and hard before
doing so. See the documentation for these for what file types are
actually supported, and what syntax types are available for each.

=head2 --syntax-empty-code-is-comment

Normally, empty lines are considered part of whatever syntax contains
them. If this Boolean option is asserted, empty code lines are
considered to be comments.

=head2 --syntax-match

If this Boolean option is asserted, C<--match (?)> will be inserted into
the C<ack> command line if either L<--syntax-type|/--syntax-type> or
L<--syntax-wc|/--syntax-wc> was seen but C<--match> was not.

This is really more suitable for the configuration file than the command
line, and was added because when I use L<--syntax-type|/--syntax-type> I
generally want the whole file but forget to give C<ack> the necessary
regular expression.

If you assert this you will need to explicitly specify C<--match> if you
want a different match expression.

=head2 --syntax-type

If this Boolean option is asserted, the four-letter syntax type of each
line is prepended to that line.

B<Note> that C<ack> expects a match expression on the command line. If
you want the whole file you can specify C<(?)> or something similar. You
can also configure L<--syntax-match|/--syntax-match>, but if you do you
will need to remember to specify C<--match> explicitly if you want a
different match expression.

=head2 --syntax-wc

If this Boolean option is asserted, the number of characters, words, and
lines of each syntax type will be appended to the output. This option
has no effect on files having unknown syntax.

B<Note> that a word is defined to be anything that matches C</\S+/>. You
may (or may not) find that the results of this option differ from
L<wc (1)> for this reason. In addition, users of operating systems that
use C<< <cr><lf> >> as the line termination may find character counts to
be low by one character per terminated line.

B<Note too> that C<ack> expects a match expression on the command line.
If you want the whole file you can specify C<(?)> or something similar.
You can also configure L<--syntax-match|/--syntax-match>, but if you do
you will need to remember to specify C<--match> explicitly if you want a
different match expression.

=head2 --syntax-wc-only

This Boolean option is like L<--syntax-wc|/--syntax-wc>, but it also
suppresses output of the file begin analyzed, making the output more
like L<wc (1)>.

B<Note> that this option has no effect on files of unknown syntax.

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
