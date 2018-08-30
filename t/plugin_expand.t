package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Plugin::Expand;
use App::AckX::Preflight::Util qw{ HASH_REF __getopt_for_plugin };
use Getopt::Long;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

use constant PLUGIN	=> 'App::AckX::Preflight::Plugin::Expand';

my @got;
my @want;


@got = PLUGIN->__options();
is_deeply \@got,
    [ qw{ expand=s% } ],
    'Options'
    or diag explain 'Got ', @got;


@got = PLUGIN->__peek_opt();
is_deeply \@got,
    [],
    'Peek options'
    or diag explain 'Got ', @got;


@got = prs( qw{ --expand manifest=--files-from=MANIFEST --manifest } );
@want = ( { expand => { manifest => '--files-from=MANIFEST' } },
    qw{ --manifest } );
is_deeply \@got, \@want,
    q<Parse '--expand manifest=... --manifest'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [ qw{ --files-from=MANIFEST } ],
    q<Process '--expand manifest=... --manifest'>
    or diag explain 'Got ', \@got;

done_testing;

1;

# ex: set textwidth=72 :
