package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Plugin::File;
use Getopt::Long;
use Test::More 0.88;	# Because of done_testing();

my @got;
my @want;


@got = App::AckX::Preflight::Plugin::File->__options();
is_deeply \@got,
    [ qw{ file=s match=s } ],
    'Options'
    or diag explain 'Got ', @got;


@got = prs( qw{ --file fu --match bar } );
@want = ( { file => 'fu', match => 'bar' } );
is_deeply \@got, \@want,
    q<Parse '--file fu --match bar'>
    or diag explain 'Got ', \@got;

my $str = eval { xqt( @want ); 'No exception'; } || $@;
like $str, qr{ \b \Qmutually exclusive\E \b }smx,
    q<Parse '--file fu --match bar' gave correct exception>;


@got = prs( qw{ --match=(?i:\bbazzle\b) } );
@want = ( { match => '(?i:\bbazzle\b)' } );
is_deeply \@got, \@want,
    q<Parse '--match=(?i:\bbazzle\b)'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got, [ qw{ --match (?i:\bbazzle\b) } ],
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
    GetOptions( $opt,
	App::AckX::Preflight::Plugin::File->__options() );
    return ( $opt, @ARGV );
}

sub xqt {
    my $opt = shift;
    local @ARGV = @_;
    App::AckX::Preflight::Plugin::File->__process( $opt );
    return @ARGV;
}

1;

# ex: set textwidth=72 :
