package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Config;
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::Perldoc';

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

my @got;
my @want;
my @dirs = (
    @INC,
    grep { defined( $_ ) && $_ ne '' && -d } map { $Config{$_} }
    qw{
	archlibexp
	privlibexp
	sitelibexp
	vendorlibexp
    }
);


@got = CLASS->__options();
is \@got,
    [ qw{ perldoc! } ],
    'Options';


@got = CLASS->__peek_opt();
is \@got,
    [],
    'Peek options';


@got = prs( qw{ --perldoc --syntax doc } );
@want = ( { perldoc => 1 }, qw{ --syntax doc } );
is \@got, \@want, q<Parse '--perldoc --syntax doc'>;

@got = xqt( @want );
is \@got, [ qw{ --syntax doc }, @dirs ];


done_testing;

1;

# ex: set textwidth=72 :
