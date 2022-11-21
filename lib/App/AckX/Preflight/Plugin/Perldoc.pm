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

    $VERSION = '0.000_039';
}

sub __options {
    return( qw{ perldelta! perldoc! } );
}

sub __process {
    my ( undef, undef, $opt ) = @_;

    my @search = (
	@INC,
	grep { defined( $_ ) && $_ ne '' && -d } map { $Config::Config{$_} }
	qw{
	    archlibexp
	    privlibexp
	    sitelibexp
	    vendorlibexp
	},
    );
    if ( $opt->{perldelta} ) {
	$opt->{perldoc}
	    and __warn '--perldoc is ignored if --perldelta is asserted';
	my @perldelta;
	File::Find::find(
	    sub {
		-d
		    and return;
		m/ \A perl [0-9]+ delta [.] pod \z /smx
		    or return;
		push @perldelta, $File::Find::name;
	    },
	    @search,
	);
	push @ARGV, sort @perldelta;
    } else {
	# Append the Perl directories to the argument list
	push @ARGV, @search;
    }

    return 1;
}

sub __wants_to_run {
    my ( undef, $opt ) = @_;
    return $opt->{perldoc} || $opt->{perldelta};
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

This causes the F<perldelta.pod> files to be searched. If both this and
C<--perldoc> are asserted

=item --perldoc

This causes the directories containing Perl documentation to be
searched.

If you want to mimic the behavior of F<perldoc-search>, also use the
F<ack> C<-l> option, which causes only the names of matching files to be
listed.

If C<--perldelta> is also asserted, this option is ignored with a
warning.

=back

This plugin's functionality can be augmented by specifying
C<--syntax=documentation> to cause only matches in module documentation
to be listed.

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
