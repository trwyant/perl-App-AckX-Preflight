package App::AckX::Preflight::Syntax::Make;

use 5.008008;

use strict;
use warnings;

require App::AckX::Preflight::Syntax;

our @ISA;

BEGIN {
    @ISA = qw{ App::AckX::Preflight::Syntax };
}

use App::AckX::Preflight::Util ();
BEGIN {
    App::AckX::Preflight::Util->import(
	qw{
	    :syntax
	    @CARP_NOT
	}
    );
}

our $VERSION;

BEGIN {
    $VERSION = '0.000_018';
}

sub __handles_syntax {
    return( SYNTAX_CODE, SYNTAX_COMMENT );
}

__PACKAGE__->__handles_type_mod( qw{ set make tcl } );

sub __classify {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    my $type = delete $attr->{continued} || (
	$_ =~ m/ \A \s* \# /smx ?
	    SYNTAX_COMMENT :
	    SYNTAX_CODE );
    $_ =~ m/ \\ $ /x
	and $attr->{continued} = $type;
    return $type;
}

sub __init {
    return;
}


1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Make - App::AckX::Preflight syntax filter for Makefiles.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Makefile-like
syntax, returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment

=back

In principal this syntax filter can be used for any syntax that consists
of code and single-line comments introduced by C<'#'>, in which the
comments can be continued by a back slash. By default it applies to:

=over

=item make

=item tcl

=back

=head1 METHODS

This class adds no new methods to its parent,
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>.

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>

L<App::AckX::Preflight|App::AckX::Preflight>

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
