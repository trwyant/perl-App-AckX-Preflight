package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use File::Find;
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::Perldoc';

use lib qw{ inc };
use My::Module::TestPlugin qw{ :all };	# Imports prs() and xqt()

my @got;
my @want;

@got = CLASS->__options();
is \@got,
    [ qw{ perldelta! perldoc! perlfaq! perlpod! } ],
    'Options';


@got = CLASS->__peek_opt();
is \@got,
    [],
    'Peek options';


@got = prs( qw{ --perldoc --syntax doc } );
@want = ( { perldoc => 1 }, qw{ --syntax doc } );
is \@got, \@want, q<Parse '--perldoc --syntax doc'>;

@got = xqt( @want );
is \@got, [ qw{ --syntax doc }, inc() ], q<Process '--perldoc --syntax doc'>;


@got = prs( qw{ --perldelta --syntax=documentation } );
@want = ( { perldelta => 1 }, qw{ --syntax=documentation } );
is \@got, \@want, q<Parse '--perldoc --syntax=documentation>;

@got = xqt( @want );
@want = ( '--syntax=documentation' );
find(
    sub {
	m/ \A perl [0-9]+ delta [.] pod \z /smx
	    and push @want, $File::Find::name;
    },
    perlpod()
);
is \@got, \@want, q<Process '--perldoc --syntax=documentation>;


@got = prs( qw{ --perlfaq -l } );
@want = ( { perlfaq => 1 }, '-l' );
is \@got, \@want, q<Parse '--perlfaq -l>;

@got = xqt( @want );
@want = ( '-l' );
find(
    sub {
	m/ \A perlfaq [0-9]+ [.] pod \z /smx
	    and push @want, $File::Find::name;
    },
    perlpod()
);
is \@got, \@want, q<Process '--perlfaq -l>;


done_testing;

1;

# ex: set textwidth=72 :
