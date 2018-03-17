package App::AckX::Preflight::Plugin::FilesFrom;

use 5.008008;

use strict;
use warnings;

use App::Ack::ConfigLoader;
use App::Ack::Filter ();
use App::Ack::Filter::Collection;
use App::Ack::Filter::Default;
use App::Ack::Filter::Extension;
use App::Ack::Filter::FirstLineMatch;
use App::Ack::Filter::Inverse;
use App::Ack::Filter::Is;
use App::Ack::Filter::IsPath;
use App::Ack::Filter::Match;
use App::Ack::Resource;
use App::AckX::Preflight::Util qw{ __open_for_read };
# use Carp ();

use parent qw{ App::AckX::Preflight::Plugin };

our $VERSION = '0.000_003';

use constant MANIFEST	=> 'MANIFEST';

sub __options {
#    return( qw{ manifest! manifest-default! } );
    return( qw{ files-from=s manifest! } );
}


sub __process {
    my ( undef, $aaxp, $opt ) = @_;

    $opt->{manifest}
	and not $opt->{'files-from'}
	and -r MANIFEST
	and $opt->{'files-from'} = MANIFEST;

    defined $opt->{'files-from'}
	or return;


    if ( MANIFEST eq $opt->{'files-from'} ) {
	require ExtUtils::Manifest;
	push @ARGV, $aaxp->__filter_files(
	    sort keys %{ ExtUtils::Manifest::maniread() },
	);
    } else {
	my $fh = __open_for_read( $opt->{'files-from'} );
	push @ARGV, $aaxp->__filter_files( map { chomp; $_ } <$fh> );
	close $fh;
    }

    return;
}
1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::FilesFrom - Provide smarter --flies-from

=head1 SYNOPSIS

 ackxp --files-from file-list.txt
 ackxp --manifest

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides a
smarter version of the C<--files-from> functionality. The file that
provides the list of files to processed is specified as a value to the
C<--files-from> option, just as for F<ack>. The alleged smarts consist
of the following:

=over

=item * Files can be filtered

That is, if you specify C<--type=> or something equivalent (like
C<--perl>), then only files of the given type will be processed.

=item * Special handling of MANIFEST

If the specified file is F<MANIFEST> it is assumed to be a Perl-format
manifest file, and it is read with C<ExtUtils::Manifest::maniread()>
rather than directly. This eliminates any comments.

=item * Optional --manifest processing

The C<--manifest> option causes the F<MANIFEST> to be processed if and
only if it is found in the default directory, and is readable by the
user. This can profitably be put in a configuration file because:

=over

=item - The C<--files-from> option overrides C<--manifest>;

=item - It can be turned off using C<--no-manifest>.

=back

=back

I am not sure of the status of the L<App::Ack|App::Ack> interface I am
using to make this happen, so this may cause problems down the road.

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
