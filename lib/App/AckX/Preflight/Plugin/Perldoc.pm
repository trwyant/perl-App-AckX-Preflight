package App::AckX::Preflight::Plugin::Perldoc;

use 5.010001;

use strict;
use warnings;

use parent qw{ App::AckX::Preflight::Plugin };

use App::AckX::Preflight::Util qw{ :all };
use Config ();
use File::Find ();

our $VERSION = '0.000_044';

sub __options {
    return( qw{ perlcore! perldelta! perldoc! perlfaq! } );
}

sub _perlpod {
    state $perlpod = do {
	my @rslt;
	# NOTE: eliminated sitelibexp and vendorlibexp since all I am
	# looking for is core Perl stuff.
	foreach my $key ( map { $Config::Config{$_} } qw{
	    archlibexp
	    privlibexp
	} ) {
	    defined $key
		and $key ne ''
		or next;
	    foreach my $dir ( qw{ pods pod } ) {
		my $path = File::Spec->catfile( $key, $dir );
		-d $path
		    or next;
		push @rslt, $path;
		last;
	    }
	}
	\@rslt;
    };
    return @{ $perlpod };
}

sub __process {
    my ( undef, undef, $opt ) = @_;

    if ( $opt->{perldelta} || $opt->{perlfaq} ) {
	$opt->{perldoc}
	    and __warn '--perldoc is ignored if --perldelta or --perlfaq is asserted';
	$opt->{perlcore}
	    and __warn '--perlcore is ignored if --perldelta  or --perlfaqis asserted';
	File::Find::find(
	    sub {
		-d
		    and return;

		$opt->{perldelta}
		    and m/ \A perl [0-9]+ delta [.] pod \z /smx
		    or $opt->{perlfaq}
		    and m/ \A perlfaq [0-9]+ [.] pod \z /smx
		    or return;

		push @ARGV, $File::Find::name;

		return;
	    },
	    _perlpod(),
	);

    } elsif ( $opt->{perlcore} ) {
	$opt->{perldoc}
	    and __warn '--perldoc is ignored if --perlcore is asserted';
	push @ARGV, _perlpod();

    } else {
	# Append the Perl directories to the argument list
	push @ARGV, grep { -d } @INC, $Config::Config{scriptdirexp};
    }

    return 1;
}

sub __wants_to_run {
    my ( undef, $opt ) = @_;
    return $opt->{perldoc} || $opt->{perldelta} || $opt->{perlfaq} ||
	$opt->{perlcore};
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

=item --perlcore

This causes the documentation for the Perl interpreter to be searched,
but not the documentation for installed modules. This takes precedence
over C<--perldoc>, and a warning is issued if C<--perldoc> is asserted.

B<Note> that a certain amount of ad-hocery is necessary to find core
Perl documentation to the exclusion of installed module documentation.
In the worst case it will find nothing at all. If this happens there
will be a test failure in F<t/plugin_perldoc.t>. The output of this
failure B<should> help figure out where I should look for the core Perl
documentation.

=item --perldelta

This causes the F<perl*delta.pod> files to be searched. This takes
precedence over both C<--perldoc> and C<--perlcore>, and a warning is
issued if either is asserted.

If C<--perlfaq> is also asserted then both deltas and FAQs are
searched.

See the note on L<--perlcore|/--perlcore> above if this option fails.

=item --perldoc

This causes the directories containing Perl documentation to be
searched.

If you want to mimic the behavior of F<perldoc-search>, also use the
F<ack> C<-l> option, which causes only the names of matching files to be
listed.

If C<--perldelta> or C<--perlcore> is also asserted, this option is
ignored with a warning.

=item --perlfaq

This causes the F<perlfaq*.pod> files to be searched. This takes
precedence over both C<--perldoc> and C<--perlcore>, and a warning is
issued if either is asserted.

If C<--perldelta> is also asserted then both deltas and FAQs are
searched.

See the note on L<--perlcore|/--perlcore> above if this option fails.

=back

This plugin's functionality can be augmented by specifying
C<--syntax=documentation> to cause only matches in module documentation
to be listed.

If you want the files in lexicographical order you can use the F<ack>
C<--sort-files> option.

If you just want the files with matches (as provided by
L<perldoc-search|perldoc-search>), you can use the F<ack> C<-l> option,
or its more-verbose version C<--flies-with-matches>.

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

Copyright (C) 2022-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
