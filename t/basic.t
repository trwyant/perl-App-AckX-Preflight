package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'App::AckX::Preflight::Util'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Util', qw{ ARRAY_REF SCALAR_REF __open_for_read }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight', qw{ new __getopt global home run }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight::Plugin'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Plugin', qw{ __options __process }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight::Plugin::File'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Plugin::File', qw{ __options __process }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight::Plugin::Manifest'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Plugin::Manifest', qw{ __options __process }
    or BAIL_OUT;


done_testing;

1;
