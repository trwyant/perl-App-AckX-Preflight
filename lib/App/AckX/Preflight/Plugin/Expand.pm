package App::AckX::Preflight::Plugin::Expand;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Plugin };

use App::AckX::Preflight::Util qw{ :all };
use Text::ParseWords ();

our $VERSION = '0.000_044';

sub __options {
    return( qw{ expand=s% } );
}

sub __process {
    my ( undef, undef, $opt ) = @_;

    my $expand = $opt->{expand};

    my $re = qr< \A --? ( @{[
	join '|', map { "\Q$_\E" } sort keys %{ $expand } ]} ) \z >smx;

    my @rslt;

    foreach ( @ARGV ) {
	if ( $_ =~ $re ) {
	    push @rslt, Text::ParseWords::shellwords( $expand->{$1} );
	} else {
	    push @rslt, $_;
	}
    }

    @ARGV = @rslt;	## no critic (RequireLocalizedPunctuationVars)

    return;
}

sub __wants_to_run {
    my ( undef, $opt ) = @_;
    return !! $opt->{expand};
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Expand - provide --expand for ackxp

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to expand a single user-specified option info multiple
command-line arguments.

In order to get this functionality, the user must specify the
C<--expand> command line option at least once. Each specification takes
a value of the form C<name=expansion>, where the C<name> is the name of
the expansion, and the C<expansion> is the expansion of that name. If
the name is specified as an unabbreviated option in the command line,
the expansion is parsed by C<Text::ParseWords::shellwords()>, and the
result of that parse replaces the original option.

Expansions are actually pretty pointless on the command line, but they
can be placed in the user's F<.ackxprc> file. For example, the entry

 --expand=manifest=--files-from MANIFEST

will cause the command

 $ ackxp -manifest foo

to be expanded to

 $ ack --files-from MANIFEST foo

B<Note> that this plug-in can not affect the options seen by other
plug-ins that have already been processed. If you want to use this
plug-in to affect other plug-ins, C<--expand> must appear before their
options. In practice this probably means putting your C<--expand>
options first in your C<.ackxprc> file.

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

Copyright (C) 2018-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
