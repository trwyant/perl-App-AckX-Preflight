package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Plugin::FilesFrom;
use Cwd qw{ getcwd };
use ExtUtils::Manifest qw{ maniread };
use Getopt::Long qw{ :config
    no_auto_version no_ignore_case no_auto_abbrev pass_through };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

use constant MANIFEST	=> 'MANIFEST';
use constant PLUGIN	=> 'App::AckX::Preflight::Plugin::FilesFrom';

my @got;
my @want;

my $cwd = getcwd();
my @manifest = sort keys %{ maniread() };
my @manifest_perl = grep {
    m/ [.] (?i: pl | pm | t ) \z /smx ||
    m| \A script/ |smx
} @manifest;

@got = PLUGIN->__options();
is_deeply \@got,
    [ qw{ files-from=s manifest! } ],
    'Options'
    or diag explain 'Got ', @got;


@got = prs( qw{ --files-from=t/data/tests } );
@want = ( { qw{ files-from t/data/tests } } );
is_deeply \@got, \@want,
    q<Parse '--files-from=t/data/tests'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [ qw{
	t/basic.t
	t/execute.t
	t/marshal.t
	t/plugin_file.t
	t/plugin_files_from.t
	t/plugin_manifest.t
	t/preflight.t
    } ],
    q<Process '--files-from=t/data/tests'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --files-from }, MANIFEST );
@want = ( { 'files-from', MANIFEST } );
is_deeply \@got, \@want,
    q<Parse '--files-from=@{[ MANIFEST ]}'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, \@manifest,
    q<Process '--files-from=@{[ MANIFEST ]}'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --manifest } );
@want = ( { manifest => 1 } );
is_deeply \@got, \@want,
    q<Parse '--manifest'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, \@manifest,
    q<Process '--manifest'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --files-from=t/data/tests --manifest } );
@want = ( { qw{ files-from t/data/tests manifest 1 } } );
is_deeply \@got, \@want,
    q<Parse '--files-from=t/data/tests --manifest'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [ qw{
	t/basic.t
	t/execute.t
	t/marshal.t
	t/plugin_file.t
	t/plugin_files_from.t
	t/plugin_manifest.t
	t/preflight.t
    } ],
    q<Process '--files-from=t/data/tests --manifest'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --manifest --no-manifest } );
@want = ( { qw{ manifest 0 } } );
is_deeply \@got, \@want,
    q<Parse '--manifest --no-manifest'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [],
    q<Process '--manifest --no-manifest'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --manifest --perl } ),
@want = ( { manifest => '1' }, '--perl' );
is_deeply \@got, \@want,
    q<Parse '--manifest --perl'>
    or diag explain 'Got ', \@got;

SKIP: {
    App::AckX::Preflight->__filter_available()
	or skip 'Test requires App::Ack filters', 1;
    @got = xqt( @want );
    is_deeply \@got, [ '--perl', @manifest_perl ],
	q<Process '--manifest --perl'>
	or diag explain 'Got ', \@got;
}


SKIP: {
    chdir 't'
	or skip "Failed to cd to t: $!", 2;

    @got = prs( qw{ --manifest } ),
    @want = ( { manifest => '1' } );
    is_deeply \@got, \@want,
	q<Parse '--manifest in t/'>
	or diag explain 'Got ', \@got;

    @got = xqt( @want );
    is_deeply \@got, [],
	q<Process '--manifest in t/'>
	or diag explain 'Got ', \@got;

    chdir $cwd;
}


done_testing;

1;

# ex: set textwidth=72 :
