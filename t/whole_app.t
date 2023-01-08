package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Util qw{ __load_module };
use File::Temp;
use IPC::Cmd ();
use Test2::V0;

use constant COPYRIGHT	=> <<'EOD';
lib/App/AckX/Preflight.pm:20:our $COPYRIGHT = 'Copyright (C) 2018-2023 by Thomas R. Wyant, III';
EOD

{
    AmigaOS	=> 1,
    'RISC OS'	=> 1,
    VMS		=> 1,
}->{$^O}
    and plan skip_all => "Fork command via -| does not work under $^O";

=begin comment

$ENV{MY_IS_GITHUB_ACTION}
    and plan skip_all => 'Skipping until I figure out why I get nothing back when run as a GitHub action';

=end comment

=cut

-x $^X
    or plan skip_all => "Somethig strange is going on. \$^X ($^X) is not executable.";

# FIXME only skip first iteration if on GitHub

foreach (
    sub {
	$ENV{MY_IS_GITHUB_ACTION}
	    and skip 'Skipping until I figure out why this doesnt run', 4;
	## return( $^X, qw{ -Mblib blib/script/ackxp } );
	return( qw{ --dispatch=system } );
    },
    sub {
	## return( $^X, qw{ -Mblib blib/script/ackxp --dispatch=none } );
	return( qw{ --dispatch=none } );
    },
) {

    SKIP: {
	my @app = $_->();

	diag '';
	diag "Testing @app";

	my $no = "N\N{U+F8}gne \N{U+D8} is a brewery in Grimstad, Agder, Norway";

	# The point of the following test is that, although the two
	# files contain the same text, they are encoded differently.
	# Ack applies no encoding, and therefore reads them as bytes.
	# Perl's internal encoding is usually UTF-8, though this is
	# officially undocumented. So a UTF-8-only test might pass even
	# without the Encode plug-in. But the internal encoding can't
	# possibly be both UTF-8 and Latin-1, and the "O with slash"
	# characters encode differently in the two encodings.
	xqt( @app, qw{
	    --noenv
	    --type-set=text:ext:txt
	    --type=text
	    --encode-type=text=utf-8
	    --encode-file=t/data/latin1.txt=latin-1
	    --sort-files
	    brewery
	    t/data
	    }, <<"EOD" ) or dump_layers();
t/data/latin1.txt:1:$no
t/data/utf8.txt:1:$no
EOD

	xqt( @app, qw{ --noenv --syntax cod -w Wyant lib/ }, COPYRIGHT )
	    or dump_layers();

	xqt( @app, qw{ --noenv --syntax-match --syntax-type --syntax-wc t/data/perl_file.PL }, <<'EOD' ) or dump_layers();
meta:#!/usr/bin/env perl
code:
code:use strict;
code:use warnings;
code:
code:printf "Hello %s!\n", @ARGV ? $ARGV[0] : 'world';
code:
meta:__END__
data:
data:This is data, kinda sorta.
data:
docu:=head1 TEST
docu:
docu:This is documentation.
docu:
docu:=cut
data:
data:# ex: set textwidth=72 :
code:	6	15	109
data:	5	13	80
docu:	5	8	67
meta:	2	3	38
EOD

	xqt( @app, qw{ --noenv --syntax code --file t/data/file lib/ },
	    COPYRIGHT )
	    or dump_layers();
    }
}

done_testing;

sub dump_layers {
    state $loaded = __load_module( 'App::AckX::Preflight::FileMonkey' );
    if ( my @layers = App::AckX::Preflight::FileMonkey->__layers() ) {
	diag 'PerlIO layers:';
	diag "  $_" for @layers;
    } else {
	diag 'PerlIO layers not available';
    }
}

sub xqt {
    my ( @arg ) = @_;
    my $want = pop @arg;

    my $out = File::Temp->new();
    local @ARGV = ( qw{ --OUT }, $out->filename(), @arg );
    my $title = "@ARGV";

    local $@ = undef;
    eval {
	App::AckX::Preflight->run();
	1;
    } or do {
	@_ = "$title did not run: $@";
	goto &fail;
    };

    seek $out, 0, 0;

    local $/ = undef;

    local $/ = undef;	# Slurp
    @_ = ( scalar( <$out> ), $want, $title );
    goto &is;
}

1;

# ex: set textwidth=72 :
