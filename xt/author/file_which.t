package main;

use 5.008008;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Test::More 0.88;	# Because of done_testing();

BEGIN {
    local $@ = undef;
    eval {
	require Module::CheckVersion;
	Module::CheckVersion->import( qw{ check_module_version } );
	1;
    } or plan skip_all => 'Module::CheckVersion needed for test';

    unshift @INC, 'inc';	# Ensure our module is found first
}

SKIP: {
    my $rslt = eval {
	check_module_version( module => 'File::Which' ) }
	or skip "File::Which version check failed: $@", 1;
    $rslt->[0] == 200
	or skip "File::Which version check failed: $rslt->[1]", 1;
    ok $rslt->[2]{is_latest_version}, 'Have latest File::Which in inc/'
	or diag <<"EOD"
File::Which versions:
    in inc/: $rslt->[2]{installed_version}
     latest: $rslt->[2]{latest_version}
EOD
}

done_testing;

1;

# ex: set textwidth=72 :
