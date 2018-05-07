package App::AckX::Preflight::Plugin::Syntax;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Syntax;
use Carp;
use List::Util 1.45 ();
use Text::Abbrev ();

use parent qw{ App::AckX::Preflight::Plugin };

our $VERSION = '0.000_008';

# sub __normalize_options {...}
*__normalize_options = \&App::AckX::Preflight::Syntax::__normalize_options;

sub __options {
    return( qw{ syntax=s@ } );
}

sub __process {
    my ( undef, $aaxp, $opt ) = @_;
    $opt->{syntax}
	and @{ $opt->{syntax} }
	or return;

    local $" = ':';
    $aaxp->__inject(
	"-MApp::AckX::Preflight::Syntax=-syntax=@{ $opt->{syntax} }" );

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

This functionality depends on the C<--syntax> option, which can take one
or more of the following values:

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
