package main;

use 5.008008;

use strict;
use warnings;

use Test2::V0;

use constant ACKXP_STANDALONE	=> 'ackxp-standalone';

if ( need_to_regenerate_ackxp_standalone() ) {
    note 'Regenerating ', ACKXP_STANDALONE;
    system { 'perl' } qw{ perl -Mblib tools/squash -o }, ACKXP_STANDALONE;
}

foreach my $app ( 'script/ackxp', ACKXP_STANDALONE ) {
    -x $app
	or next;

    note "Testing $app";

    xqt( $app, qw{ --noenv -syntax code -w Wyant lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:29:    $COPYRIGHT = 'Copyright (C) 2018-2020 by Thomas R. Wyant, III';
EOD
    xqt( $app, qw{ --noenv -syntax-type --syntax-wc t/data/perl_file.PL }, <<'EOD' );
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

    xqt( $app, qw{ --noenv -syntax code -file t/data/file lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:29:    $COPYRIGHT = 'Copyright (C) 2018-2020 by Thomas R. Wyant, III';
EOD
}

done_testing;

# We need to regenerate ackxp-standalone if:
# * It does not exist, or
# * App::Ack is newer.
sub need_to_regenerate_ackxp_standalone {
    -x ACKXP_STANDALONE
	or return 1;
    my $ackxp_mv = ( stat _ )[9];
    require App::Ack;
    my $ack_mv = ( stat $INC{'App/Ack.pm'} )[9];
    return $ackxp_mv < $ack_mv;
}

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
