package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
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
	    and skip 'Skipping until I figure out why this doesnt run', 3;
	return( $^X, qw{ -Mblib blib/script/ackxp } );
    },
    sub {
	return( $^X, qw{ -Mblib blib/script/ackxp --dispatch=none } );
    },
) {

    SKIP: {
	my @app = $_->();

	-x $app[0]
	    or next;

	diag '';
	diag "Testing @app";

	xqt( \@app, qw{ --noenv --syntax cod -w Wyant lib/ }, COPYRIGHT );

	xqt( \@app, qw{ --noenv --syntax-match --syntax-type --syntax-wc t/data/perl_file.PL }, <<'EOD' );
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

	xqt( \@app, qw{ --noenv --syntax code --file t/data/file lib/ }, COPYRIGHT );
    }
}

done_testing;

sub xqt {
    my ( $app, @arg ) = @_;
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
