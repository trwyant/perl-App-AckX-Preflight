package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Plugin::File;
use App::AckX::Preflight::Util qw{ HASH_REF __getopt_for_plugin };
use Getopt::Long;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

use constant PLUGIN	=> 'App::AckX::Preflight::Plugin::File';

my @got;
my @want;


@got = PLUGIN->__options();
is_deeply \@got,
    [ qw{ file=s file-extended! } ],
    'Options'
    or diag explain 'Got ', @got;


@got = PLUGIN->__peek_opt();
is_deeply \@got,
    [ qw{ match=s } ],
    'Peek options'
    or diag explain 'Got ', @got;


@got = prs( qw{ --file fu --match bar } );
@want = ( { file => 'fu', match => 'bar' }, qw{ --match bar } );
is_deeply \@got, \@want,
    q<Parse '--file fu --match bar'>
    or diag explain 'Got ', \@got;

my $str = eval { xqt( @want ); 'No exception'; } || $@;
like $str, qr{ \b \Qmutually exclusive\E \b }smx,
    q<Parse '--file fu --match bar' gave correct exception>;


@got = prs( qw{ --match=(?i:\bbazzle\b) } );
@want = ( { match => '(?i:\bbazzle\b)' }, qw{ --match=(?i:\bbazzle\b) } );
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


@got = prs( qw{ --file=t/data/foo --literal } ),
# The following _is_ really what we want, because the --literal is not
# parsed out of the command line until we know we have the --file.
@want = ( { file => 't/data/foo' }, '--literal' );
is_deeply \@got, \@want,
    q<Parse '--file=t/data/foo --literal'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got,
    [ qw{ --match \(\?i\:\\\\bfoo\\\\b\) } ],
    'Process --file=t/data/foo --literal'
    or diag explain 'Got ', \@got;


SKIP: {

    '5.010' le $]
	or skip( "Perl 5.10 required; this is $]", 4 );

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

    @got = prs( qw{ --file=t/data/foo-extended } );
    @want = ( { file => 't/data/foo-extended' } );
    is_deeply \@got, \@want,
	q<Parse '--file=t/data/foo-extended'>
	or diag explain 'Got ', \@got;

    @got = xqt( @want );
    is_deeply \@got,
        [ '--match', '(?|(?#)|(?:# This is a comment)|(?i:\bfoo\b))' ],
	'--file=t/data/foo-extended'
	or diag explain 'Got ', \@got;
}

@got = prs( qw{ --file=t/data/foo-extended --file-extended } );
@want = ( { file => 't/data/foo-extended', 'file-extended' => 1 } );
is_deeply \@got, \@want,
    q<Parse '--file=t/data/foo-extended --file-extended'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got,
    [ qw{ --match (?i:\bfoo\b) } ],
    '--file=t/data/foo-extended --file-extended'
    or diag explain 'Got ', \@got;

@got = prs( qw{ foo --match=bar bazzle } );
@want = ( { match => 'bar' }, qw{ foo --match=bar bazzle } );
is_deeply \@got, \@want,
    q<Parse 'foo --match=bar bazzle'>
    or diag explain 'Got ', \@got;

@got = xqt( @want );
is_deeply \@got,
    [ qw{ foo --match=bar bazzle } ],
    q<Process 'foo --match=bar bazzle'>
    or diag explain 'Got ', \@got;



done_testing;

1;

# ex: set textwidth=72 :
