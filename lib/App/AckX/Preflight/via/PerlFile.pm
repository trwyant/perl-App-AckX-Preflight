package App::AckX::Preflight::via::PerlFile;

use 5.008008;

use strict;
use warnings;

use Carp;

our $VERSION = '0.000_007';

our %CONTENT_TYPE = ( code => 1 );

{
    my %valid = map { $_ => 1 } qw{ code pod };

    sub import {
	my ( undef, @arg ) = @_;
	foreach my $type ( @arg ) {
	    $valid{$type}
		or croak "Perl file content type '$type' invalid";
	    %CONTENT_TYPE = ( $type => 1 );
	}
	return;
    }
}

sub type {
    return ( qw{ perl } );
}

sub FILL {
    my ( $self, $fh ) = @_;
    {
	defined( my $line = <$fh> )
	    or last;
	if ( $line =~ m/ \A = ( cut \b )? /smx ) {
	    $self->{in} = $1 ? 'code' : 'pod';
	}
	$CONTENT_TYPE{$self->{in}}
	    and return $line;
	redo;
    }
    return;
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;
    return bless {
	in	=> 'code',
    }, ref $class || $class;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::via::PerlFile - PerlIO::via layer to return only code or POD from a Perl file.

=head1 SYNOPSIS

 $ perl -MApp::AckX::Preflight::Resource \
     -MApp::AckX::Preflight::via::PerlFile=pod -S ack ...

=head1 DESCRIPTION

This Perl module implements a pure-Perl PerlIO layer to read a Perl file
and return only code or only POD. Lines of the wrong type are never
returned, but are represented in the value of C<$.>. Whether code or
data are returned depends on the most-recently-imported of C<'code'> or
C<'pod'>, with C<'code'> being the default.

If it is being injected into F<ack> it needs
L<App::AckX::Preflight::Resource> to bootstrap it in.

=head1 METHODS

This class supports the following public methods, over and above those
required for L<PerlIO::via|PerlIO::via> support:

=head2 import

The only valid arguments are C<'code'> or C<'pod'>. The last-seen
determines what sort of data are returned, with the default being
C<'code'>.

=head2 type

This method returns the types supported by this layer: to wit
C<( qw{ perl } )>.

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
