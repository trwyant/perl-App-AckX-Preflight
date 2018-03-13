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
use Carp;

our $VERSION = '0.000_01';

use constant MANIFEST	=> 'MANIFEST';

sub __options {
    return( qw{ manifest! manifest-default! } );
}


sub __process {
    my ( undef, $opt ) = @_;

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

    # TODO the filter logic probably belongs on ::Preflight.

    my @filters;

    {	# Purpose of block is to localize @ARGV

	local @ARGV = @ARGV;

	my @arg_sources = App::Ack::ConfigLoader::retrieve_arg_sources();

	my %known_type;
	my $argv;

	foreach my $as ( @arg_sources ) {
	    if ( 'ARGV' eq $as->{name} ) {
		$argv = $as;
	    } else {
		my @contents = @{ $as->{contents} };
		while ( @contents ) {
		    local $_ = shift @contents;
		    if ( m/ \A --? type- ( add | set | del )
			( = ( [^:]+) | \z ) /smx ) {
			my $verb = $1;
			my $type = $3;
			unless ( $type ) {
			    local $_ = shift @contents;
			    m/ \A ( [^:]+ ) /smx
				or next;
			    $type = $1;
			}
			if ( 'del' eq $verb ) {
			    delete $known_type{$type};
			} else {
			    $known_type{$type} = 1;
			}
		    }
		}
	    }
	}

	if ( $argv ) {
	    my @contents = @{ $argv->{contents} };
	    my @rslt;
	    while ( @contents ) {
		local $_ = shift @contents;
		if ( m/ \A --? type ( = | \z ) /smx ) {
		    push @rslt, $_;
		    $1
			or push @rslt, shift @contents;
		} elsif ( m/ \A --? ( [[:alpha:]0-9]+ ) \z /smx &&
		    $known_type{$1} ) {
		    push @rslt, $_;
		}
	    }
	    @{ $argv->{contents} } = @rslt;
	}

	my $opt = App::Ack::ConfigLoader::process_args( @arg_sources );

	@filters = @{ $opt->{filters} };

    }	# End localized @ARGV

    require ExtUtils::Manifest;

    my @manifest = sort keys %{ ExtUtils::Manifest::maniread() };

    foreach ( @manifest ) {
	my $r = App::Ack::Resource->new( $_ );
	foreach my $f ( @filters ) {
	    $f->filter( $r )
		or next;
	    push @ARGV, $_;
	    last;
	}
    }

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
