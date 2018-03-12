package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Plugin::Manifest;
use Cwd qw{ getcwd };
use ExtUtils::Manifest qw{ maniread };
use Getopt::Long;
use Test::More 0.88;	# Because of done_testing();

use constant PACKAGE	=> 'App::AckX::Preflight::Plugin::Manifest';

my @got;
my @want;

my $cwd = getcwd();
my @manifest = sort keys %{ maniread() };

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

done_testing; exit;


SKIP: {

    '5.010' le $]
	or skip( "Perl 5.10 required; this is $]", 2 );

    @got = prs( qw{ --file=t/data/fubar } );
    @want = ( { file => 't/data/fubar' } );
    is_deeply \@got, \@want,
	q<Parse '--file=t/data/fubar'>
	or diag explain 'Got ', \@got;

    @got = xqt( @want );
    is_deeply \@got,
	[ qw{ --match (?|(?i:\bfu\b)|(?i:\bbar\b)) } ],
	'--file=t/data/fubar'
	or diag explain 'Got ', \@got;
}


@got = prs( qw{ foo --match=bar bazzle } );
@want = ( { match => 'bar' }, qw{ foo bazzle } );
is_deeply \@got, \@want,
    q<Parse 'foo --match=bar bazzle'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got,
    [ qw{ --match bar foo bazzle } ],
    q<Process 'foo --match=bar bazzle'>
    or diag explain 'Got ', \@got;



done_testing;

sub prs {
    local @ARGV = @_;
    my $opt = {};
    GetOptions( $opt, PACKAGE->__options() );
    return ( $opt, @ARGV );
}

sub xqt {
    my $opt = shift;
    local @ARGV = @_;
    PACKAGE->__process( $opt );
    return @ARGV;
}

1;

# ex: set textwidth=72 :
