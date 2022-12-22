package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use File::Find;
use List::Util 1.45 qw{ all };
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::Perldoc';

use lib qw{ inc };
use My::Module::TestPlugin qw{ :all };	# Imports prs() and xqt()

my @got;
my @want;

@got = CLASS->__options();
is \@got,
    [ qw{ perlcore! perldelta! perldoc! perlfaq! } ],
    'Options';


@got = CLASS->__peek_opt();
is \@got,
    [],
    'Peek options';

@got = CLASS->_perlpod();
@want = perlpod();
is \@got, \@want, 'Got expected Perl pod directories';

{
    # FIXME This block and the other FIXME annotations in this file are
    # due to my efforts to track down GitHub CI failures under the
    # current Ubuntu, but Perl 5.10.1. The failure is
    # Error: invalid top directory at ../lib/5.10.1/File/Find.pm line 598.
    # I do not know which version this is, but my 5.10.1 has File::Find
    # 1.14, and generates this message at this line if the first (and
    # only the first) directory to search is undef.

    diag 'File::Find version ', File::Find->VERSION();

    my $got = all { defined } @got;
    ok $got, 'All _perlpod() results are defined'
	or diag CLASS, '->_perlpod() returned ( ',
	    join( ', ', map { defined() ? "'$_'" : 'undef' } @got ), ' )';

    $got = all { defined } @want;
    ok $got, 'All _perlpod() results are defined'
	or diag 'perlpod() (i.e. the test routine) returned ( ',
	    join( ', ', map { defined() ? "'$_'" : 'undef' } @want ), ' )';
}

@got = prs( qw{ --perldoc --syntax doc } );
@want = ( { perldoc => 1 }, qw{ --syntax doc } );
is \@got, \@want, q<Parse '--perldoc --syntax doc'>;

@got = xqt( @want );
is \@got, [ qw{ --syntax doc }, inc() ], q<Process '--perldoc --syntax doc'>;


@got = prs( qw{ --perlcore -w NaN } );
@want = ( { perlcore => 1 }, qw{ -w NaN } );
is \@got, \@want, q<Parse --perlcore -w NaN>;

@got = xqt( @want );
@want = ( qw{ -w NaN }, perlpod() );
is \@got, \@want,  q<Process --perlcore -w NaN>;


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
    grep { defined }	# FIXME These OUGHT to all be defined, but ...
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
    grep { defined }	# FIXME These OUGHT to all be defined, but ...
    perlpod()
);
is \@got, \@want, q<Process '--perlfaq -l>;


done_testing;

1;

# ex: set textwidth=72 :
