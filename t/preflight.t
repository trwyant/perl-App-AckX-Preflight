package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Cwd qw{ abs_path };
use ExtUtils::Manifest qw{ maniread };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Preflight;

delete @ENV{ qw{ ACKXPRC ACKXP_OPTIONS } };
my @manifest = sort keys %{ maniread() };

my @got;

is_deeply [ My::Module::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Manifest
	} ],
    'Plugins';

is_deeply xqt( qw{ --noenv A B C } ),
    [ qw{ ack --noenv A B C } ],
    'No reversal by default';

is_deeply xqt( qw{ --noenv --nomanifest A B C } ),
    [ qw{ ack --noenv A B C } ],
    '--nomanifest';

is_deeply xqt( qw{ --noenv --manifest A B C } ),
    [ qw{ ack --noenv A B C }, @manifest ],
    '--manifest';

is_deeply xqt( qw{ --noenv --file t/data/foo } ),
    [ qw{ ack --match (?i:\bfoo\b) --noenv } ],
    '--file t/data/foo';

SKIP: {

    '5.010' le $]
	or skip( "Perl 5.10 required; this is $]", 1 );

    is_deeply xqt( qw{ --noenv --file t/data/fubar } ),
	[ qw{ ack --match (?|(?i:\bfu\b)|(?i:\bbar\b)) --noenv } ],
	'--file t/data/fubar';
}

# Test combining plug-ins.

@got = @{ xqt( qw{ --noenv --manifest --file t/data/foo } ) };
is_deeply \@got,
    [ qw{ ack --match (?i:\bfoo\b) --noenv }, @manifest ],
    '--manifest --file t/data/foo'
    or diag 'Got ', explain \@got;

is_deeply xqt( qw{ --noenv --ackxprc t/data/ackxprc } ),
    [ qw{ ack --from=t/data/ackxprc --noenv } ],
    '--ackxprc t/data/ackxprc';

{
    my $aaxp = My::Module::Preflight->new(
	global	=> abs_path( 't/data/global' ),
	home	=> abs_path( 't/data/home' ),
    );

    my $ackxprc = abs_path( 't/data/project/_ackxprc' );

    chdir 't/data/project';

    local $ENV{ACKXP_OPTIONS} = '--ackxp-options=ACKXP_OPTIONS';

    is_deeply xqt( $aaxp, qw{ --command-line } ),
	[ qw{ ack
	    --global=t/data/global/ackxprc
	    --home=t/data/home/_ackxprc
	    --project=t/data/project/_ackxprc
	    --ackxp-options=ACKXP_OPTIONS
	    --command-line } ],
	'Pick up configuration'
	    or diag 'Got ', explain xqt( $aaxp, qw{ fubar } );

    local $ENV{ACKXPRC} = $ackxprc;

    is_deeply xqt( $aaxp, qw{ --command-line } ),
	[ qw{ ack
	    --global=t/data/global/ackxprc
	    --project=t/data/project/_ackxprc
	    --ackxp-options=ACKXP_OPTIONS
	    --command-line } ],
	'ACKXPRC plus deduplicaiton'
	    or diag 'Got ', explain xqt( $aaxp, qw{ fubar } );
}

done_testing;

sub xqt {
    local @ARGV = @_;
    my $invocant = ref $ARGV[0] ? shift @ARGV : 'My::Module::Preflight';

    return [ $invocant->run() ];

}

1;

# ex: set textwidth=72 :
