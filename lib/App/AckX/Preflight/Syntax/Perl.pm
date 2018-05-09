package App::AckX::Preflight::Syntax::Perl;

use 5.008008;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Syntax };

use App::AckX::Preflight::Util qw{
    :syntax
    @CARP_NOT
};

our $VERSION = '0.000_008';

sub __handles_syntax {
    return(
	SYNTAX_CODE,
	SYNTAX_COMMENT,
	SYNTAX_DATA,
	SYNTAX_DOCUMENTATION,
    );
}

__PACKAGE__->__handles_type_mod( qw{ set perl perltest } );

{
    my %is_data = map {; "__${_}__\n" => 1 } qw{ DATA END };

    sub FILL {
	my ( $self, $fh ) = @_;
	{
	    defined( my $line = <$fh> )
		or last;
	    if ( $line =~ m/ \A = cut \b /smx ) {
		$self->{in} = $self->{cut};
		# We have to hand-dispatch the line because although the
		# next line is whatever we were working on before the
		# POD was encountered, the '=cut' itself is POD.
		$self->{want}{ SYNTAX_DOCUMENTATION() }
		    and return $line;
		redo;
	    } elsif ( $line =~ m/ \A = [A-Za-z] /smx ) {
		$self->{cut} = $self->{in};
		$self->{in} = SYNTAX_DOCUMENTATION;
	    } elsif ( SYNTAX_DOCUMENTATION eq $self->{in} ) {
		# Nothing else can be in POD
	    } elsif ( SYNTAX_CODE eq $self->{in} && $line =~ m/ \A \s* \# /smx ) {
		$self->{want}{ SYNTAX_COMMENT() }
		    and return $line;
		redo;
	    } elsif ( $is_data{$line} ) {
		$self->{in} = SYNTAX_DATA;
	    }
	    $self->{want}{$self->{in}}
		and return $line;
	    redo;
	}
	return;
    }
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;
    return bless {
	in	=> SYNTAX_CODE,
	want	=> $class->__want_syntax(),
    }, ref $class || $class;
}


1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax::Perl - App::AckX::Preflight syntax filter for Perl.

=head1 SYNOPSIS

No direct user interaction.

=head1 DESCRIPTION

This L<PerlIO::via|PerlIO::via> I/O layer is intended to be used by
L<App::AckX::Preflight|App::AckX::Preflight> to process a Perl file,
returning only those lines the user has requested.

The supported syntax types are:

=over

=item code

=item comment (i.e. comments)

=item data (non-POD stuff after __DATA__ and/or __END__)

=item documentation (i.e. POD)

=back

=head1 METHODS

This class adds the following methods, which are part of the
L<PerlIO::via|PerlIO::via> interface:

=head2 PUSHED

This static method is called when this class is pushed onto the stack.
It manufactures, initializes, and returns a new object.

=head2 FILL

This method is called when a C<readline>/C<< <> >> operator is executed
on the file handle. It reads the next-lower-level layer until a line is
found that is one of the syntax types that is being returned, and
returns that line to the next-higher layer. At end of file, nothing is
returned.

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
