package App::AckX::Preflight::Plugin::PerlFile;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{ __err_exclusive };

use parent qw{ App::AckX::Preflight::Plugin };

our $VERSION = '0.000_007';

sub __options {
    return( qw{ perl-code perl-pod } );
}

sub __process {
    my ( undef, $aaxp, $opt ) = @_;
    my $uses = grep { $opt->{$_} } __options()
	or return;
    2 == $uses
	and __err_exclusive( __options() );
    my $type = $opt->{ 'perl-code' } ? 'code' : 'pod';
    $aaxp->__inject( "-MApp::AckX::Preflight::via::PerlFile=$type" );
    return;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::PerlFile - Provide --perl-code and --perl-pod for ackxp

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to search only code or only POD in Perl files.

In order to get this functionality, the user must specify C<--perl-code>
to get code, or C<--perl-pod> to get POD. It is an error to specify
both.

This works by a hot patch that replaces
C<< App::Ack::Resource->open() >> with a version that uses the
C<App::Ack> type system to determine if the file being opened is a Perl
file. If so, and if it is being opened for a scan (determined from the
results of C<caller()>), the file is opened
C<< '<:via(App::AckX::Preflight::via::PerlFile)' >>. Whether C<'code'>
or C<'pod'> is imported on load determines whether code or POD is
returned.

This all works because L<App::Ack|App::Ack> uses C<$.> to determine the
displayed line number. Since the C<::via::PerlFile> logic uses the
C<readline()> built-in, C<$.> is maintained, and the calling code is
oblivious to the fact that the line after C<12> is C<42>.

Use of this functionality may produce strange results if C<ack> options
C<-A>, C<--after-context>, C<-B>, or C<--before-context> are used. As of
F<ack> C<2.22> these seem to me to work sanely given the information
F<ack> has to work with. That is, the requisite number of code or POD
lines are displayed, correctly numbered (somewhat to my surprise) if
numbers are being displayed. But I can not guarantee this behaviour.

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
