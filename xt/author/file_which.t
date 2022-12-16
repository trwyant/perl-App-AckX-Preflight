package main;

use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Test2::V0;
use Test2::Tools::LoadModule;

use lib qw{ inc };	# Ensure we find the File::Which in inc/.

load_module_or_skip_all 'Module::CheckVersion';

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
