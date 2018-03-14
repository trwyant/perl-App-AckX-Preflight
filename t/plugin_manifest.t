package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Plugin::Manifest;
use Cwd qw{ getcwd };
use ExtUtils::Manifest qw{ maniread };
use Getopt::Long qw{ :config
    no_auto_version no_ignore_case no_auto_abbrev pass_through };
use Test::More 0.88;	# Because of done_testing();

use constant PACKAGE	=> 'App::AckX::Preflight::Plugin::Manifest';

my @got;
my @want;

my $cwd = getcwd();
my @manifest = sort keys %{ maniread() };
my @manifest_perl = grep {
    m/ [.] (?i: pl | pm | t ) \z /smx ||
    m| \A script/ |smx
} @manifest;

@got = PACKAGE->__options();
is_deeply \@got,
    [ qw{ manifest! manifest-default! } ],
    'Options'
    or diag explain 'Got ', @got;


@got = prs( qw{ --nomanifest } );
@want = ( { manifest => '0' } );
is_deeply \@got, \@want,
    q<Parse '--nomanifest'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [],
    q<Process '--nomanifest'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --manifest } ),
@want = ( { manifest => '1' } );
is_deeply \@got, \@want,
    q<Parse '--manifest'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, \@manifest,
    q<Process '--manifest'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --manifest --perl } ),
@want = ( { manifest => '1' }, '--perl' );
is_deeply \@got, \@want,
    q<Parse '--manifest --perl'>
    or diag explain 'Got ', \@got;

SKIP: {
    App::AckX::Preflight->__filter_support()
	or skip 'Test requires App::Ack filters', 1;
    @got = xqt( @want );
    is_deeply \@got, [ '--perl', @manifest_perl ],
	q<Process '--manifest --perl'>
	or diag explain 'Got ', \@got;
}


@got = prs( qw{ --nomanifest-default } );
@want = ( { 'manifest-default' => '0' } );
is_deeply \@got, \@want,
    q<Parse '--nomanifest-default'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [],
    q<Process '--nomanifest-default'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --manifest-default } ),
@want = ( { 'manifest-default' => '1' } );
is_deeply \@got, \@want,
    q<Parse '--manifest-default'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, \@manifest,
    q<Process '--manifest-default'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --nomanifest --manifest-default } ),
@want = ( { manifest => '0', 'manifest-default' => '1' } );
is_deeply \@got, \@want,
    q<Parse '--nomanifest --manifest-default'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [],
    q<Process '--nomanifest --manifest-default'>
    or diag explain 'Got ', \@got;


SKIP: {
    chdir 't'
	or skip "Failed to cd to t: $!", 1;

    @got = xqt( @want );
    is_deeply \@got, [],
	q<Process '--manifest-default executed in t/'>
	or diag explain 'Got ', \@got;

    local $@ = undef;

    my $str = eval { xqt( { manifest => 1 } ); 'No exception' } || $@;
    like $str, qr{ \b \QNo such file\E \b }smx,
    '--manifest in t/ gave correct exception';

    chdir $cwd;
}


done_testing;

{
    my $psr;

    BEGIN {
	$psr = Getopt::Long::Parser->new();
	$psr->configure( qw{
	    no_auto_version no_ignore_case no_auto_abbrev pass_through
	    },
	);
    }

    sub prs {
	local @ARGV = @_;
	my $opt = {};
	$psr->getoptions( $opt, PACKAGE->__options() );
	return ( $opt, @ARGV );
    }
}

use constant HASH_REF	=> ref {};

sub xqt {
    local @ARGV = @_;
    my $aaxp = 'App::AckX::Preflight' eq ref $ARGV[0] ?
	shift @ARGV :
	App::AckX::Preflight->new();
    my $opt = HASH_REF eq ref $ARGV[0] ? shift @ARGV : {};
    PACKAGE->__process( $aaxp, $opt );
    return @ARGV;
}

1;

# ex: set textwidth=72 :
