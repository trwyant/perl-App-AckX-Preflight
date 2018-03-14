package main;

use strict;
use warnings;

use Test::More 0.88;

use constant PACKAGE	=> 'App::AckX::Preflight';

require_ok PACKAGE
    or BAIL_OUT $@;

can_ok PACKAGE, qw{ new __getopt run }
    or BAIL_OUT;

done_testing;

1;
