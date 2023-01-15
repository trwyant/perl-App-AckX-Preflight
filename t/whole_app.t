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

# FIXME don't want to skip first iteration on GitHub

foreach (
    sub {
	$ENV{MY_IS_GITHUB_ACTION}
	    and skip 'Skipping until I figure out why this doesnt run', 4;
	## return( $^X, qw{ -Mblib blib/script/ackxp } );
	return( qw{ system } );
    },
    sub {
	## return( $^X, qw{ -Mblib blib/script/ackxp --dispatch=none } );
	return( qw{ none } );
    },
) {

    SKIP: {
	my ( $dispatch, @app ) = $_->();
	unshift @app, "--dispatch=$dispatch";

	my $dispatch_none = $dispatch eq 'none';

	diag '';
	diag "Testing @app";

	{
	    # NOTE I can't seem to convince ack to accept a UTF-16 file.
	    # Fortunately MiniAck is more docile.
	    my $no = "N\N{U+F8}gne \N{U+D8} is a brewery in Grimstad, Agder, Norway";
	    my @files = sort( qw{ t/data/latin1.txt t/data/utf8.txt },
		$dispatch_none ? ( 't/data/utf16le.txt' ) : ()
	    );
	    my $want = join '', map { "$_:1:$no\n" } @files;

	    # The point of the following test is that, although the
	    # files contain the same text, they are encoded differently.
	    # Ack applies no encoding, and therefore reads them as
	    # bytes.  Perl's internal encoding is usually UTF-8, though
	    # this is officially undocumented. So a UTF-8-only test
	    # might pass even without the Encode plug-in. But the
	    # internal encoding can't possibly be both UTF-8 and
	    # Latin-1, and the "O with slash" characters encode
	    # differently in the encodings.
	    xqt( @app, qw{
		--noenv
		--type-set=text:ext:txt
		--type=text
		--encoding=utf-8:type:text
		--encoding=latin-1:is:t/data/latin1.txt
		--encoding=utf16le:match:/utf16le.txt
		--sort-files
		brewery
		}, @files, $want ) or dump_layers();
	}

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

my @LAYERS;

sub dump_layers {
    if ( @LAYERS ) {
	diag 'PerlIO layers:';
	diag "  $_" for @LAYERS;
    } else {
	diag 'PerlIO layers not available';
    }
}

sub xqt {
    my ( @arg ) = @_;
    my $want = pop @arg;

    my $out = File::Temp->new();
    local @ARGV = (
	qw{ --OUT }, $out->filename(),
	qw{ --output-encoding utf-8 },
	@arg,
    );
    my $title = "@ARGV";

    local $@ = undef;
    eval {
	App::AckX::Preflight->run();
	1;
    } or do {
	@_ = "$title did not run: $@";
	goto &fail;
    };

    # NOTE that if I just read <$out> I get the \r\n line endings under
    # Windows. No idea why -- I verified the presence of :crlf.
    my $got = do {
	open my $fh, '<:encoding(utf-8)', $out->filename()
	    or die 'Failed to open ', $out->filename(), ": $!";
	local $/ = undef;
	<$fh>;
    };

    @_ = ( $got, $want, $title );
    goto &is;
}

1;

# ex: set textwidth=72 :
