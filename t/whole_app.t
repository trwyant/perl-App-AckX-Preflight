package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Util qw{ __load_module };
use File::Temp;
use IPC::Cmd ();
use Test2::V0;

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

# NOTE all this slurp() stuff is because for some reason I do not fathom
# these tests fail under Windows because the file input gets line
# terminations "\r\n". Where the \r come from I have no idea, since the
# file itself is still Unix line endings, and the :crlf layer is present
# under Windows. I considered just bunging a "\r" onto each line of the
# desired input under Windows, but it seemed both more maintainable and
# (slightly) less arbitrary to run the desired output through the PerlIO
# mechanism instead.
my $copyright = slurp( \<<'EOD' );
lib/App/AckX/Preflight.pm:20:our $COPYRIGHT = 'Copyright (C) 2018-2023 by Thomas R. Wyant, III';
EOD

my $nogne_o = do {
    my $no = "N\x{F8}gne \x{D8} is a brewery in Grimstad, Agder, Norway";
    slurp( \<<"EOD", ':encoding(latin-1)' );
t/data/latin1.txt:1:$no
t/data/utf8.txt:1:$no
EOD
};

my $syntax_type = slurp( \<<'EOD', ':encoding(latin-1)' );
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

	my $no = slurp( \<<"EOD", ':encoding(latin-1)' );
N\x{F8}gne \x{D8} is a brewery in Grimstad, Agder, Norway
EOD

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
	    }, $nogne_o ) or dump_layers();

	xqt( @app, qw{ --noenv --syntax cod -w Wyant lib/ }, $copyright )
	    or dump_layers();

	xqt( @app, qw{
	    --noenv --syntax-match --syntax-type --syntax-wc
	    t/data/perl_file.PL
	    }, $syntax_type ) or dump_layers();

	xqt( @app, qw{ --noenv --syntax code --file t/data/file lib/ },
	    $copyright )
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

sub slurp {
    my ( $file, $encoding ) = @_;
    $encoding //= '';
    open my $fh, "<$encoding", $file
	or die "Unable to open $file: $!";
    local $/ = undef;
    return <$fh>;
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
