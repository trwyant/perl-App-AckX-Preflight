package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Test::More 0.88;	# Because of done_testing();

ok( App::AckX::Preflight->__filter_available(),
    'App::Ack file filters are available' );

done_testing;

1;

# ex: set textwidth=72 :
