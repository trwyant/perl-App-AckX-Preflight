package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Util qw{ :ref };
use Cwd qw{ abs_path };
use ExtUtils::Manifest qw{ maniread };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Preflight;

delete @ENV{ qw{ ACKXPRC ACKXP_OPTIONS } };
my @manifest = sort keys %{ maniread() };

my $got;

is_deeply [ My::Module::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Syntax
	} ],
    'Plugins';

is_deeply xqt( qw{ --noenv A B C } ),
    [ qw{ perl -S ack --noenv A B C } ],
    'No reversal by default';

=begin comment

is_deeply xqt( qw{ --noenv --nomanifest A B C } ),
    [ qw{ perl -S ack --noenv A B C } ],
    '--nomanifest';

is_deeply xqt( qw{ --noenv --manifest A B C } ),
    [ qw{ perl -S ack --noenv A B C }, @manifest ],
    '--manifest';

=end comment

=cut

is_deeply xqt( qw{ --noenv --file t/data/foo } ),
    [ qw{ perl -S ack --match (?i:\bfoo\b) --noenv } ],
    '--file t/data/foo';

SKIP: {

    '5.010' le $]
	or skip( "Perl 5.10 required; this is $]", 1 );

    is_deeply xqt( qw{ --noenv --file t/data/fubar } ),
	[ qw{ perl -S ack --match (?|(?i:\bfu\b)|(?i:\bbar\b)) --noenv } ],
	'--file t/data/fubar';
}

# Test combining plug-ins.

=begin comment

$got = xqt( qw{ --noenv --manifest --file t/data/foo } );
is_deeply $got,
    [ qw{ perl -S ack --match (?i:\bfoo\b) --noenv }, @manifest ],
    '--manifest --file t/data/foo'
    or diag 'got ', explain $got;

=end comment

=cut

is_deeply xqt( qw{ --noenv --ackxprc t/data/ackxprc } ),
    [ qw{ perl -S ack --from=t/data/ackxprc --noenv } ],
    '--ackxprc t/data/ackxprc';

=begin comment

$got = xqt( qw{ --noenv --files-from t/data/relative --relative } );
is_deeply $got,
    [ qw{ perl -S ack --noenv t/data/foo t/data/fubar } ],
    '--noenv --files-from t/data/relative --relative'
    or diag 'got ', explain $got;

=end comment

=cut

$got = xqt( qw{ --disable FilesFrom --files-from t/data/relative } );
is_deeply $got,
    [ qw{
	perl
	-S
	ack
	--files-from
	t/data/relative
	} ],
    '--disable FilesFrom --files-from t/data/relative'
    or diag 'Got ', explain $got;

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

    is_deeply xqt( $aaxp, qw{ --command-line } ),
	[ qw{
	    perl
	    -S
	    ack
	    --global=t/data/global/ackxprc
	    --home=t/data/home/_ackxprc
	    --project=t/data/project/_ackxprc
	    --ackxp-options=ACKXP_OPTIONS
	    --command-line } ],
	'Pick up configuration'
	    or diag 'Got ', explain xqt( $aaxp, qw{ fubar } );

    local $ENV{ACKXPRC} = $ackxprc;

    is_deeply xqt( $aaxp, qw{ --command-line } ),
	[ qw{
	    perl
	    -S
	    ack
	    --global=t/data/global/ackxprc
	    --project=t/data/project/_ackxprc
	    --ackxp-options=ACKXP_OPTIONS
	    --command-line } ],
	'ACKXPRC plus deduplicaiton'
	    or diag 'Got ', explain xqt( $aaxp, qw{ fubar } );
}

$got = xqt( qw{ --syntax=code } );
is_deeply $got,
    [ qw{
	perl
	-Mblib
	-MApp::AckX::Preflight::Syntax=-syntax=code
	-S
	ack
	--project=t/data/project/_ackxprc
	} ],
    '--syntax=code'
	or diag 'Got ', explain $got;

$got = xqt( qw{ --syntax data } );
is_deeply $got,
    [ qw{
	perl
	-Mblib
	-MApp::AckX::Preflight::Syntax=-syntax=data
	-S
	ack
	--project=t/data/project/_ackxprc
	} ],
    '--syntax=data'
	or diag 'Got ', explain $got;

$got = xqt( qw{ --syntax doc } );
is_deeply $got,
    [ qw{
	perl
	-Mblib
	-MApp::AckX::Preflight::Syntax=-syntax=documentation
	-S
	ack
	--project=t/data/project/_ackxprc
	} ],
    '--syntax=doc'
	or diag 'Got ', explain $got;

{
    $got = xqt( qw{ --syntax code;doc } );
    is_deeply $got,
	[ qw{
	    perl
	    -Mblib
	    -MApp::AckX::Preflight::Syntax=-syntax=code:documentation
	    -S
	    ack
	    --project=t/data/project/_ackxprc
	    } ],
	'--syntax code;doc'
	    or diag 'Got ', explain $got;
}

$got = xqt( qw{ --syntax=code:data:doc } );
is_deeply $got,
    [ qw{
	perl
	-Mblib
	-MApp::AckX::Preflight::Syntax=-syntax=code:data:documentation
	-S
	ack
	--project=t/data/project/_ackxprc
	} ],
    '--syntax=code:data:doc'
	or diag 'Got ', explain $got;

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
