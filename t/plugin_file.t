package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use Getopt::Long;
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::File';

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

my @got;
my @want;


@got = CLASS->__options();
is \@got,
    [ qw{ file=s file-extended! } ],
    'Options';


@got = CLASS->__peek_opt();
is \@got,
    [ qw{ match=s } ],
    'Peek options';

@got = prs( qw{ --file fu --match bar } );
@want = ( { file => 'fu', match => 'bar' }, qw{ --match bar } );
is \@got, \@want,
    q<Parse '--file fu --match bar'>;

like dies { xqt_unsafe( @want ) },
    qr{ \b \Qmutually exclusive\E \b }smx,
    q<Parse '--file fu --match bar' gave correct exception>;


@got = prs( qw{ --match=(?i:\bbazzle\b) } );
@want = ( { match => '(?i:\bbazzle\b)' }, qw{ --match=(?i:\bbazzle\b) } );
is \@got, \@want,
    q<Parse '--match=(?i:\bbazzle\b)'>;

@got = xqt( @want );
is \@got, [ qw{ --match=(?i:\bbazzle\b) } ],
    q<Process '--match=(?i:\bbazzle\b)'>;


@got = prs( qw{ --file=t/data/foo } ),
@want = ( { file => 't/data/foo' } );
is \@got, \@want,
    q<Parse '--file=t/data/foo'>;

@got = xqt( @want );
is \@got,
    [ qw{ --match (?i:\bfoo\b) } ],
    'Process --file=t/data/foo';


@got = prs( qw{ --file=t/data/foo --literal } ),
# The following _is_ really what we want, because the --literal is not
# parsed out of the command line until we know we have the --file.
@want = ( { file => 't/data/foo' }, '--literal' );
is \@got, \@want,
    q<Parse '--file=t/data/foo --literal'>;

@got = xqt( @want );
is \@got,
    [ qw{ --match \(\?i\:\\\\bfoo\\\\b\) } ],
    'Process --file=t/data/foo --literal';


@got = prs( qw{ --file=t/data/fubar } );
@want = ( { file => 't/data/fubar' } );
is \@got, \@want,
    q<Parse '--file=t/data/fubar'>;

@got = xqt( @want );
is \@got,
    [ qw{ --match (?|(?i:\bfu\b)|(?i:\bbar\b)) } ],
    '--file=t/data/fubar';

@got = prs( qw{ --file=t/data/foo-extended } );
@want = ( { file => 't/data/foo-extended' } );
is \@got, \@want,
    q<Parse '--file=t/data/foo-extended'>;

@got = xqt( @want );
is \@got,
    [ '--match', '(?|(?#)|(?:# This is a comment)|(?i:\bfoo\b))' ],
    '--file=t/data/foo-extended';

@got = prs( qw{ --file=t/data/foo-extended --file-extended } );
@want = ( { file => 't/data/foo-extended', 'file-extended' => 1 } );
is \@got, \@want,
    q<Parse '--file=t/data/foo-extended --file-extended'>;

@got = xqt( @want );
is \@got,
    [ qw{ --match (?i:\bfoo\b) } ],
    '--file=t/data/foo-extended --file-extended';

@got = prs( qw{ foo --match=bar bazzle } );
@want = ( { match => 'bar' }, qw{ foo --match=bar bazzle } );
is \@got, \@want,
    q<Parse 'foo --match=bar bazzle'>;

@got = xqt( @want );
is \@got,
    [ qw{ foo --match=bar bazzle } ],
    q<Process 'foo --match=bar bazzle'>;



done_testing;

1;

# ex: set textwidth=72 :
