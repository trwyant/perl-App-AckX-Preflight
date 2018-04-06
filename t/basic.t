package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'App::AckX::Preflight::Util'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Util', qw{
    ARRAY_REF HASH_REF SCALAR_REF
    __die __getopt __getopt_for_plugin __open_for_read __warn
    }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight', qw{ new global home run }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight::Plugin'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Plugin',
    qw{ IN_SERVICE __options __peek_opt __process }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight::Plugin::File'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Plugin::File',
    qw{ IN_SERVICE __options __peek_opt __process }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight::Plugin::FilesFrom'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Plugin::FilesFrom',
    qw{ IN_SERVICE __options __peek_opt __process }
    or BAIL_OUT;

done_testing;

1;
