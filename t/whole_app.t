package main;

use 5.008008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

unless ( -x 'ackxp-standalone' ) {
    system { 'perl' } qw{ perl -Mblib tools/squash -o ackxp-standalone };
}

foreach my $app ( qw{ script/ackxp ackxp-standalone } ) {
    -x $app
	or next;

    note "Testing $app";

    xqt( $app, qw{ --noenv -syntax code -w Wyant lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:29:    $COPYRIGHT = 'Copyright (C) 2018-2019 by Thomas R. Wyant, III';
EOD
    xqt( $app, qw{ --noenv -syntax-type . t/data/perl_file.PL }, <<'EOD' );
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
EOD

    xqt( $app, qw{ --noenv -syntax code -file t/data/file lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:29:    $COPYRIGHT = 'Copyright (C) 2018-2019 by Thomas R. Wyant, III';
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
