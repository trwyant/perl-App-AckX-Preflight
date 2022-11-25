package main;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use constant IS_WINDOWS	=> { map { $_ => 1 } qw{ dos MSWin32 } }->{$^O};

eval {
    require Test::Prereq::Meta;
    1;
} or plan skip_all => 'Test::Prereq::Meta not available';

my $tpm = Test::Prereq::Meta->new(
    accept	=> IS_WINDOWS ? [] :
	[ qw{ Win32 Win32::ShellQuote } ],
);

$tpm->all_prereq_ok();

$tpm->all_prereqs_used();

done_testing;

1;

# ex: set textwidth=72 :
