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

    $VERSION = '0.000_018';
}

sub __options {
    return( qw{ syntax=s@ syntax-type! } );
}

sub __process {
    my ( undef, $aaxp, $opt ) = @_;
    $opt->{syntax}
	and @{ $opt->{syntax} }
	or $opt->{'syntax-type'}
	or return;

    my @arg = App::AckX::Preflight::Syntax->__get_syntax_opt( \@ARGV, $opt );

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

=head2 --syntax-type

If this Boolean option is asserted, the four-letter syntax type of each
line is prepended to that line.

If you are trying to get a dump of the syntax types of a file, remember
that because this is C<ack>, you must specify a pattern. Something like
C<'.'> will be useful here.


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
