package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Cwd qw{ abs_path };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Test qw{ -noexec -search-test };

delete @ENV{ qw{ ACKXPRC ACKXP_OPTIONS } };

is_deeply [ sort App::AckX::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Reverse
	} ],
    'Plugins';

is_deeply xqt( qw{ --noenv A B C } ),
    [ qw{ ack --noenv A B C } ],
    'No reversal by default';

is_deeply xqt( qw{ --noenv --noreverse A B C } ),
    [ qw{ ack --noenv A B C } ],
    '--noreverse';

is_deeply xqt( qw{ --noenv --reverse A B C } ),
    [ qw{ ack C B A --noenv } ],
    '--reverse';

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

# Test combining non-transitive plug-ins.

is_deeply xqt( qw{ --noenv --reverse t/data/foo --file t/data/fubar } ),
    [ qw{ ack --match (?i:\bfoo\b) t/data/fubar --noenv } ],
    '--reverse --file';

is_deeply xqt( qw{ --noenv --file t/data/foo --reverse fubar } ),
    [ qw{ ack fubar --noenv (?i:\bfoo\b) --match } ],	# This won't execute
    '--file --reverse';

is_deeply xqt( qw{ --noenv --ackxprc t/data/ackxprc } ),
    [ qw{ ack --from=t/data/ackxprc --noenv } ],
    '--ackxprc t/data/ackxprc';

{
    my $aaxp = App::AckX::Preflight->new(
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
    my $invocant = ref $ARGV[0] ? shift @ARGV : 'App::AckX::Preflight';

    return [ $invocant->run() ];

}

1;

# ex: set textwidth=72 :
