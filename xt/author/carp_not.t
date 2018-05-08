package main;

use 5.006;

use strict;
use warnings;

use ExtUtils::Manifest qw{ maniread };
use App::AckX::Preflight::Util qw{ @CARP_NOT };
use Test::More 0.88;	# Because of done_testing();

my @modules;
foreach my $fn ( sort keys %{ maniread() } ) {
    local $_ = $fn;
    s< \A lib/ ><>smx
	or next;
    s< [.] pm \z ><>smx
	or next;
    s< / ><::>smxg;
    push @modules, $_;

    require_ok $_;	# Redundant with t/basic.t, but loads module.

    SKIP: {
	$_->can( 'IN_SERVICE' )
	    and not $_->IN_SERVICE
	    and skip "$_ is not in service", 1;

	my $stash = "${_}::";
	no strict qw{ refs };
	ok defined $$stash{CARP_NOT}, "$_ assigns \@CARP_NOT";
    }
}
is_deeply \@CARP_NOT, \@modules,
    'Ensure that @App::AckX::Preflight::Util::CARP_NOT is correct';

done_testing;

1;

# ex: set textwidth=72 :
