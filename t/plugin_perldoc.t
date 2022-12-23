package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use File::Find;
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::Perldoc';

use lib qw{ inc };
use My::Module::TestPlugin qw{ :all };	# Imports prs() and xqt()

use constant NO_PERL_CORE	=> 'No perl core documentation found';

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

my @PERLPOD = CLASS->_perlpod();

cmp_ok scalar @PERLPOD, '>', 0,
    'Found at least one core Perl documentation directory'
    or do {
    require Config;
    foreach my $item ( qw{
	    archlibexp
	    privlibexp
	    sitelibexp
	    vendorlibexp
	} ) {
	my $path = $Config::Config{$item};
	if ( ! defined $path ) {
	    diag "$item is undefined";
	} elsif ( $path eq '' ) {
	    diag "$item is empty";
	} else {
	    my $extant = -d $path ? 'exists' : 'does not exist';
	    diag "$item is $path, which $extant";
	}
    }
    local $@ = undef;
    eval {
	find(
	    sub {
		-d
		    and return;
		$_ eq 'perldelta.pod'
		    or return;
		diag "Found perldelta.pod in $File::Find::dir";
		die;
	    },
	    inc(),
	);
	1;
    } and diag "Unable to find perldelta.pod. No idea where it went.";
};

@got = prs( qw{ --perldoc --syntax doc } );
@want = ( { perldoc => 1 }, qw{ --syntax doc } );
is \@got, \@want, q<Parse '--perldoc --syntax doc'>;

@got = xqt( @want );
is \@got, [ qw{ --syntax doc }, inc() ], q<Process '--perldoc --syntax doc'>;


@got = prs( qw{ --perlcore -w NaN } );
@want = ( { perlcore => 1 }, qw{ -w NaN } );
is \@got, \@want, q<Parse --perlcore -w NaN>;

SKIP: {
    @PERLPOD
	or skip NO_PERL_CORE, 1;

    @got = xqt( @want );
    @want = ( qw{ -w NaN }, @PERLPOD );
    is \@got, \@want,  q<Process --perlcore -w NaN>;
}


@got = prs( qw{ --perldelta --syntax=documentation } );
@want = ( { perldelta => 1 }, qw{ --syntax=documentation } );
is \@got, \@want, q<Parse '--perldelta --syntax=documentation>;

SKIP: {
    @PERLPOD
	or skip NO_PERL_CORE, 1;

    @got = xqt( @want );
    @want = ( '--syntax=documentation' );
    find(
	sub {
	    m/ \A perl [0-9]+ delta [.] pod \z /smx
		and push @want, $File::Find::name;
	},
	@PERLPOD,
    );
    is \@got, \@want, q<Process '--perldelta --syntax=documentation>;
}

@got = prs( qw{ --perlfaq -l } );
@want = ( { perlfaq => 1 }, '-l' );
is \@got, \@want, q<Parse '--perlfaq -l>;

SKIP: {
    @PERLPOD
	or skip NO_PERL_CORE, 1;

    @got = xqt( @want );
    @want = ( '-l' );
    find(
	sub {
	    m/ \A perlfaq [0-9]+ [.] pod \z /smx
		and push @want, $File::Find::name;
	},
	@PERLPOD,
    );
    is \@got, \@want, q<Process '--perlfaq -l>;
}

done_testing;

1;

# ex: set textwidth=72 :
