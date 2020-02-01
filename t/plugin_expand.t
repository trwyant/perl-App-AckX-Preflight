package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Util qw{ HASH_REF __getopt_for_plugin };
use Getopt::Long;
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::Expand';

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

my @got;
my @want;


@got = CLASS->__options();
is \@got,
    [ qw{ expand=s% } ],
    'Options';


@got = CLASS->__peek_opt();
is \@got,
    [],
    'Peek options';


@got = prs( qw{ --expand manifest=--files-from=MANIFEST --manifest } );
@want = ( { expand => { manifest => '--files-from=MANIFEST' } },
    qw{ --manifest } );
is \@got, \@want,
    q<Parse '--expand manifest=... --manifest'>;

@got = xqt( @want );
is \@got, [ qw{ --files-from=MANIFEST } ],
    q<Process '--expand manifest=... --manifest'>;

done_testing;

1;

# ex: set textwidth=72 :
