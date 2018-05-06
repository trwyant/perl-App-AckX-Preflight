package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Plugin::Syntax;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

use constant PLUGIN	=> 'App::AckX::Preflight::Plugin::Syntax';

my @got;
my @want;


@got = PLUGIN->__options();
is_deeply \@got,
    [ qw{ syntax=s@ } ],
    'Options'
    or diag explain 'Got ', @got;


@got = PLUGIN->__peek_opt();
is_deeply \@got, [],
    'Peek options'
    or diag explain 'Got ', @got;


@got = prs( qw{ --syntax code } );
@want = ( { syntax => [ qw{ code } ] } ); 
is_deeply \@got, \@want,
    q<Parse '--syntax code'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --syntax code --fubar baz } );
@want = ( { syntax => [ qw{ code } ] }, qw{ --fubar baz } ); 
is_deeply \@got, \@want,
    q<Parse '--syntax code --fubar baz'>
    or diag explain 'Got ', \@got;


@got = prs( '--syntax=code,doc' );
@want = ( { syntax => [ qw{ code doc } ] } ); 
is_deeply \@got, \@want,
    q<Parse '--syntax=code,doc'>
    or diag explain 'Got ', \@got;


@got = prs( qw{ --syntax code --syntax doc --syntax data:code } );
@want = ( { syntax => [ qw{ code doc data } ] } ); 
is_deeply \@got, \@want,
    q<Parse '--syntax code --syntax doc --syntax data:code'>
    or diag explain 'Got ', \@got;


done_testing;

1;

# ex: set textwidth=72 :
