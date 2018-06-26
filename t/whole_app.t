package main;

use 5.008008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

foreach my $app ( qw{ script/ackxp script/ackxp-standalone } ) {
    -x $app
	or next;

    note "Testing $app";

    xqt( $app, qw{ -syntax code -w Wyant lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:28:    $COPYRIGHT = 'Copyright (C) 2018 by Thomas R. Wyant, III';
EOD

    xqt( $app, qw{ -syntax code -file t/data/file lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:28:    $COPYRIGHT = 'Copyright (C) 2018 by Thomas R. Wyant, III';
EOD
}

done_testing;

sub xqt {
    my @arg = @_;
    my $want = pop @arg;
    my $title = "@arg";
    $arg[0] =~ m/ standalone /smx
	or unshift @arg, '-Mblib';
    unshift @arg, $^X;
    my $stdout = `@arg`;
    $?  and die "\$ @arg: $?";
    @_ = ( $stdout, $want, $title );
    goto \&is;
}

1;

# ex: set textwidth=72 :
