package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Test qw{ -noexec -search-test };

is_deeply [ sort App::AckX::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Reverse
	} ],
    'Plugins';

is_deeply xqt( qw{ A B C } ),
    [ qw{ ack A B C } ],
    'No reversal by default';

is_deeply xqt( qw{ --noreverse A B C } ),
    [ qw{ ack A B C } ],
    '--noreverse';

is_deeply xqt( qw{ --reverse A B C } ),
    [ qw{ ack C B A } ],
    '--reverse';

is_deeply xqt( qw{ --file t/data/foo } ),
    [ qw{ ack --match (?i:\bfoo\b) } ],
    '--file t/data/foo';

SKIP: {

    '5.010' le $]
	or skip( "Perl 5.10 required; this is $]", 1 );

    is_deeply xqt( qw{ --file t/data/fubar } ),
	[ qw{ ack --match (?|(?i:\bfu\b)|(?i:\bbar\b)) } ],
	'--file t/data/fubar';
}

# Test combining non-transitive plug-ins.

is_deeply xqt( qw{ --reverse t/data/foo --file t/data/fubar } ),
    [ qw{ ack --match (?i:\bfoo\b) t/data/fubar } ],
    '--reverse --file';

is_deeply xqt( qw{ --file t/data/foo --reverse fubar } ),
    [ qw{ ack fubar (?i:\bfoo\b) --match } ],	# This won't execute
    '--file --reverse';

done_testing;

sub xqt {
    local @ARGV = @_;

    return [ App::AckX::Preflight->run() ];

}

1;

# ex: set textwidth=72 :
