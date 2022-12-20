package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Util qw{ :ref };
use Config;
use Cwd qw{ abs_path };
use ExtUtils::Manifest qw{ maniread };
use IPC::Cmd qw{ can_run };
use Test2::V0;

use lib qw{ inc };
use My::Module::Preflight;
use My::Module::TestPlugin qw{ :dirs };

delete @ENV{ qw{ ACKXPRC ACKXP_OPTIONS } };
my @manifest = sort keys %{ maniread() };

my $ack = can_run( 'ack' )
    or plan skip_all => q<Executable 'ack' not found>;

my $got;

is [ My::Module::Preflight->__plugins() ],
    [ qw{
	    App::AckX::Preflight::Plugin::Expand
	    App::AckX::Preflight::Plugin::File
	    App::AckX::Preflight::Plugin::Perldoc
	    App::AckX::Preflight::Plugin::Syntax
	} ],
    'Plugins';

is xqt( qw{ --noenv A B C } ),
    [
	$^X,
	$ack,
	qw{ --noenv A B C },
    ],
    'No reversal by default';

is xqt( qw{ --noenv --file t/data/foo } ),
    [
	$^X,
	$ack,
	qw{ --match (?i:\bfoo\b) --noenv },
    ],
    '--file t/data/foo';

is xqt( qw{ --noenv --file t/data/fubar } ),
    [
	$^X,
	$ack,
	qw{ --match (?|(?i:\bfu\b)|(?i:\bbar\b)) --noenv },
    ],
    '--file t/data/fubar';

# Test combining plug-ins.

is xqt( qw{ --noenv --ackxprc t/data/ackxprc } ),
    [
	$^X,
	$ack,
	qw{ --from=t/data/ackxprc --noenv },
    ],
    '--ackxprc t/data/ackxprc';

{
    local $@ = undef;

    $got = eval { xqt( qw{ --disable Fubar } ); 'No exception' } || $@;
    like $got, qr{ \b \QUnknown plugin\E \b }smx,
	'Disable unknown plugin gave correct exception';

    $got = eval { xqt( qw{ --enable Fubar } ); 'No exception' } || $@;
    like $got, qr{ \b \QUnknown plugin\E \b }smx,
	'Enable unknown plugin gave correct exception';

    $got = eval {
	xqt( qw{ --disable Fubar --enable Baz } );
	'No exception'
    } || $@;
    like $got, qr{ \b \QUnknown plugins\E \b }smx,
	'Multiple unknown plugins gave correct exception';
}

SKIP: {
    my $aaxp = My::Module::Preflight->new(
	global	=> abs_path( 't/data/global' ),
	home	=> abs_path( 't/data/home' ),
    );

    my $ackxprc = abs_path( 't/data/project/_ackxprc' );

    chdir 't/data/project'
	or skip "Failed to cd to t/data/project: $!", 2;

    local $ENV{ACKXP_OPTIONS} = '--ackxp-options=ACKXP_OPTIONS';

    is xqt( $aaxp, qw{ --command-line } ),
	[
	    $^X,
	    $ack,
	    qw{
		--global=t/data/global/ackxprc
		--home=t/data/home/_ackxprc
		--project=t/data/project/_ackxprc
		--ackxp-options=ACKXP_OPTIONS
		--command-line
	    },
	],
	'Pick up configuration';

    local $ENV{ACKXPRC} = $ackxprc;

    is xqt( $aaxp, qw{ --command-line } ),
	[
	    $^X,
	    $ack,
	    qw{
		--global=t/data/global/ackxprc
		--project=t/data/project/_ackxprc
		--ackxp-options=ACKXP_OPTIONS
		--command-line
	    },
	],
	'ACKXPRC plus deduplicaiton';
}

$got = xqt( qw{ --noenv --syntax=code } );
is $got,
    [
	$^X,
	qw{
	    -Mblib
	    -MApp::AckX::Preflight::Syntax=--syntax=code
	},
	$ack,
	qw{
	    --noenv
	},
    ],
    '--noenv --syntax=code';

$got = xqt( qw{ --noenv --syntax data } );
is $got,
    [
	$^X,
	qw{
	    -Mblib
	    -MApp::AckX::Preflight::Syntax=--syntax=data
	},
	$ack,
	qw{
	    --noenv
	},
    ],
    '--noenv --syntax=data';

$got = xqt( qw{ --noenv --syntax doc } );
is $got,
    [
	$^X,
	qw{
	    -Mblib
	    -MApp::AckX::Preflight::Syntax=--syntax=documentation
	},
	$ack,
	qw{
	    --noenv
	},
    ],
    '--noenv --syntax=doc';

{
    $got = xqt( qw{ --noenv --syntax code;doc } );
    is $got,
	[
	    $^X,
	    qw{
		-Mblib
		-MApp::AckX::Preflight::Syntax=--syntax=code:documentation
	    },
	    $ack,
	    qw{
		--noenv
	    },
	],
	'--noenv --syntax code;doc';
}

$got = xqt( qw{ --noenv --syntax=code:data:doc } );
is $got,
    [
	$^X,
	qw{
	    -Mblib
	    -MApp::AckX::Preflight::Syntax=--syntax=code:data:documentation
	},
	$ack,
	qw{
	    --noenv
	} ],
    '--noenv --syntax=code:data:doc';

$got = xqt( qw{ --noenv --perldoc } );
is $got,
    [
	$^X,
	$ack,
	qw{
	    --noenv
	},
	inc(),
    ],
    '--noenv --perldoc';

$got = xqt( qw{ --noenv --perldoc --default=perldoc=--syntax=doc } );
is $got,
    [
	$^X,
	qw{
	    -Mblib
	    -MApp::AckX::Preflight::Syntax=--syntax=documentation
	},
	$ack,
	qw{
	    --noenv
	},
	inc(),
    ],
    '--noenv --perldoc --default=perldoc=--syntax=doc';

done_testing;

sub xqt {
    local @ARGV = @_;
    my $invocant = 'My::Module::Preflight' eq ref $ARGV[0] ?
	shift @ARGV :
	My::Module::Preflight->new();

    my $arg = ARRAY_REF eq ref @ARGV ? shift @ARGV : [];

    return [ $invocant->run( @{ $arg } ) ];

}

1;

# ex: set textwidth=72 :
