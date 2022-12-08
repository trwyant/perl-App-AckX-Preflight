package App::AckX::Preflight::Plugin::Perldoc;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Plugin;
use App::AckX::Preflight::Util qw{ SYNTAX_DOCUMENTATION __warn };
use Config ();
use File::Find ();

our @ISA;

our $VERSION;

BEGIN {

    App::AckX::Preflight::Util->import(
	qw{
	    :all
	}
    );
    @ISA = qw{ App::AckX::Preflight::Plugin };

    $VERSION = '0.000_040';
}

sub __options {
    return( qw{ perldelta! perldoc! perlpod! } );
}

{
    my @perlpod;
    sub _perlpod {
	$DB::single = 1;
	unless ( @perlpod ) {
	    foreach my $key ( map { $Config::Config{$_} } qw{
		archlibexp
		privlibexp
		sitelibexp
		vendorlibexp
	    } ) {
		defined $key
		    and $key ne ''
		    or next;
		my $dir = File::Spec->catfile( $key, 'pods' );
		-d $dir
		    or next;
		push @perlpod, $dir;
	    }
	}
	return @perlpod;
    }
}

sub __process {
    my ( undef, undef, $opt ) = @_;

    if ( $opt->{perldelta} ) {
	$opt->{perldoc}
	    and __warn '--perldoc is ignored if --perldelta is asserted';
	$opt->{perlpod}
	    and __warn '--perlpod is ignored if --perldelta is asserted';
	File::Find::find(
	    sub {
		-d
		    and return;
		m/ \A perl [0-9]+ delta [.] pod \z /smx
		    or return;
		push @ARGV, $File::Find::name;
	    },
	    _perlpod(),
	);
    } elsif ( $opt->{perlpod} ) {
	$opt->{perldoc}
	    and __warn '--perldoc is ignored if --perlpod is asserted';
	File::Find::find(
	    sub {
		-d
		    and return;
		m/ [.] pod \z /smx
		    or return;
		push @ARGV, $File::Find::name;
	    },
	    _perlpod(),
	);
    } else {
	# Append the Perl directories to the argument list
	push @ARGV, grep { -d } @INC;
    }

    return 1;
}

sub __wants_to_run {
    my ( undef, $opt ) = @_;
    return $opt->{perldoc} || $opt->{perldelta} || $opt->{perlpod};
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Perldoc - Provide --perldoc for ackxp

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to search the installed Perl modules in a manner similar to
L<App:Perldoc::Search|App:Perldoc::Search>.

The following options are available:

=over

=item --perldelta

This causes the F<perldelta.pod> files to be searched. This takes
precedence over both C<--perldoc> and C<--perlpod>, and a warning is
issued if either is asserted.

=item --perldoc

This causes the directories containing Perl documentation to be
searched.

If you want to mimic the behavior of F<perldoc-search>, also use the
F<ack> C<-l> option, which causes only the names of matching files to be
listed.

If C<--perldelta> or C<--perlpod> is also asserted, this option is
ignored with a warning.

=item --perlpod

This causes the documentation for the Perl interpreter to be searched,
but not the documentation for installed modules. This takes precedence
over C<--perldoc>, and a warning is issued if C<--perldoc> is asserted.

=back

This plugin's functionality can be augmented by specifying
C<--syntax=documentation> to cause only matches in module documentation
to be listed.

If you want the files in lexicographical order you can use the F<ack>
C<--sort-files> option.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
