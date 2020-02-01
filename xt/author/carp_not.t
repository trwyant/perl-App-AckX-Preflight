package main;

use 5.006;

use strict;
use warnings;

use ExtUtils::Manifest qw{ maniread };
use App::AckX::Preflight::Util qw{ @CARP_NOT };
use Test2::V0;
use Test2::Tools::LoadModule;

my %carp_allowed = map { $_ => 1 } qw{
    App::AckX::Preflight::Util
};

my @modules;
foreach my $fn ( sort keys %{ maniread() } ) {
    local $_ = $fn;
    s< \A lib/ ><>smx
	or next;
    s< [.] pm \z ><>smx
	or next;
    s< / ><::>smxg;
    push @modules, $_;

    load_module_ok $_;	# Redundant with t/basic.t, but loads module.

    SKIP: {
	$_->can( 'IN_SERVICE' )
	    and not $_->IN_SERVICE
	    and skip "$_ is not in service", 1;

	my $stash = "${_}::";
	no strict qw{ refs };
	ok defined $$stash{CARP_NOT}, "$_ assigns \@CARP_NOT";
    }

    SKIP: {
	$carp_allowed{$_}
	    and skip "'use Carp;' is allowed in $_";

	local $/ = undef;
	open my $fh, '<', $fn
	    or die "Failed to open $fn: $!";
	my $content = <$fh>;
	close $fh;

	unlike $content, qr/ \b use \s+ Carp \b /smx,
	    "$_ should not 'use Carp;'";
    }
}
is \@CARP_NOT, \@modules,
    'Ensure that @App::AckX::Preflight::Util::CARP_NOT is correct';

done_testing;

1;

# ex: set textwidth=72 :
