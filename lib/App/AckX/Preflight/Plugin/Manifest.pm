package App::AckX::Preflight::Plugin::Manifest;

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

our $VERSION = '0.000_002';

use constant MANIFEST	=> 'MANIFEST';

sub __options {
    return( qw{ manifest! manifest-default! } );
}


sub __process {
    my ( undef, $aaxp, $opt ) = @_;

    if ( defined $opt->{manifest} ) {
	$opt->{manifest}
	    or return;
	__open_for_read( MANIFEST );	# To get an error if unreadable.
    } elsif ( $opt->{'manifest-default'} ) {
	-r MANIFEST
	    or return;
    } else {
	return;
    }

    require ExtUtils::Manifest;

    push @ARGV, $aaxp->__filter_files(
	sort keys %{ ExtUtils::Manifest::maniread() } );

    return;
}
1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Manifest - Provide --manifest for ackxp

=head1 SYNOPSIS

 ackxp --manifest
 ackxp --manifest-default

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to add the contents of the MANIFEST files to the command line.
It differs from C<--files-from=MANIFEST> in that it uses
C<ExtUtils::Manifest::maniread()> to strip comments from the input.

The functionality is controlled by the C<--manifest> and
C<--manifest-default> options.

If asserted, the Boolean C<--manifest> option specifies that the
F<MANIFEST> file be read unconditionally. A fatal error occurs if it can
not be read. This option can be negated (as C<--nomanifest>) to prevent
C<--manifest-default> (below) from causing a F<MANIFEST> file to be
read.

If asserted, the Boolean C<--manifest-default> option specifies that the
F<MANIFEST> file be read only if it is in fact readable; otherwise this
plug-in does nothing. If C<--manifest> is specified anywhere (command
line or resource file) this option is ignored. It is really intended
more for use in a configuration file.

Any C<--type=> options (or equivalent) are applied to the manifest, so
that something like C<--manifest --perl> selects only Perl files, using
F<ack>'s definition of Perl files. I am not sure of the status of the
L<App::Ack|App::Ack> interface I am using to make this happen, so this
may cause problems down the road.

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
