package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Plugin::File;
use Getopt::Long;
use Test::More 0.88;	# Because of done_testing();

use constant PACKAGE	=> 'App::AckX::Preflight::Plugin::File';

my @got;
my @want;


@got = PACKAGE->__options();
is_deeply \@got,
    [ qw{ file=s } ],
    'Options'
    or diag explain 'Got ', @got;


@got = prs( qw{ --file fu --match bar } );
@want = ( { file => 'fu' }, qw{ --match bar } );
is_deeply \@got, \@want,
    q<Parse '--file fu --match bar'>
    or diag explain 'Got ', \@got;

my $str = eval { xqt( @want ); 'No exception'; } || $@;
like $str, qr{ \b \Qmutually exclusive\E \b }smx,
    q<Parse '--file fu --match bar' gave correct exception>;


@got = prs( qw{ --match=(?i:\bbazzle\b) } );
@want = ( {}, '--match=(?i:\bbazzle\b)' );
is_deeply \@got, \@want,
    q<Parse '--match=(?i:\bbazzle\b)'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [ qw{ --match=(?i:\bbazzle\b) } ],
    q<Process '--match=(?i:\bbazzle\b)'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --file=t/data/foo } ),
@want = ( { file => 't/data/foo' } );
is_deeply \@got, \@want,
    q<Parse '--file=t/data/foo'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got,
    [ qw{ --match (?i:\bfoo\b) } ],
    'Process --file=t/data/foo'
    or diag explain 'Got ', \@got;


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
@want = ( {}, qw{ foo --match=bar bazzle } );
is_deeply \@got, \@want,
    q<Parse 'foo --match=bar bazzle'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got,
    [ qw{ foo --match=bar bazzle } ],
    q<Process 'foo --match=bar bazzle'>
    or diag explain 'Got ', \@got;



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
