package App::AckX::Preflight::Syntax::_single_line_comments;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Syntax ();
use App::AckX::Preflight::Util ();

our @ISA;

our $VERSION;

BEGIN {
    App::AckX::Preflight::Util->import(
	qw{
	    :croak
	    :syntax
	    @CARP_NOT
	}
    );

    @ISA = qw{ App::AckX::Preflight::Syntax };

    $VERSION = '0.000_037';
}

sub __classify {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    if ( 1 == $. && $attr->{shebang_re} && $_ =~ $attr->{shebang_re} ) {
	return SYNTAX_METADATA;
    } elsif ( $attr->{single_line_doc_re} &&
	$_ =~ $attr->{single_line_doc_re} ) {
	return SYNTAX_DOCUMENTATION;
    } elsif ( $attr->{single_line_re} &&
	$_ =~ $attr->{single_line_re} ) {
	return SYNTAX_COMMENT;
    } else {
	return SYNTAX_CODE;
    }
}

sub __init {
    my ( $self ) = @_;
    my $attr = $self->__my_attr();
    $attr->{shebang_re}		= $self->__shebang_re();
    $attr->{single_line_re}	= $self->__single_line_re();
    $attr->{single_line_doc_re}	= $self->__single_line_doc_re();
    return;
}

sub __shebang_re {
    return;
}

sub __single_line_re {
    __die_hard( '__single_line_re() must be overridden' );
}

sub __single_line_doc_re {
    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::_single_line_comments - App::AckX::Preflight syntax filter for languages which only have single-line comments.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This Perl class is intended to be subclassed to produce a
This L<PerlIO::via|PerlIO::via> I/O layer used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a language whose
syntax allows only single-line comments, and no in-line data or
documentation.

In order to use this as a superclass, the subclass B<must> override
L<__handles_syntax|App::AckX::Preflight::Syntax/__handles_syntax> and
L<__single_line_re()|/__single_line_re>.

=head1 METHODS

This class is a subclass of
L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>. It adds or
overrides the following methods:

=head2 __classify

=head2 __init

=head2 __shebang_re

If the syntax supports a shebang line, this method returns a regular
expression that matches it; otherwise it returns nothing.

This specific method returns nothing. Subclasses that support a shebang
will need to override this method to return a suitable C<Regexp>.

=head2 __single_line_re

This method returns a regular expression that matches a comment line, or
nothing if the syntax does not support single-line comments.

This method B<must> be overridden by a subclass.

=head2 __single_line_doc_re

This method returns a regular expression that matches a single-line
in-line documentation line, or nothing if the syntax does not support
single-line in-line documentation.

This implementation returns nothing. The subclass should override this
only if it is trying to parse a syntax having single-line in-line
documentation.

=head2 PUSHED

This static method is part of the L<PerlIO::via|PerlIO::via> interface.
It is called when this class is pushed onto the stack.  It manufactures,
initializes, and returns a new object.

=head2 FILL

This method is part of the L<PerlIO::via|PerlIO::via> interface. It is
called when a C<readline>/C<< <> >> operator is executed on the file
handle. It reads the next-lower-level layer until a line is found that
is one of the syntax types that is being returned, and returns that line
to the next-higher layer. At end of file, nothing is returned.

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>

L<App::AckX::Preflight|App::AckX::Preflight>

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
