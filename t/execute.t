package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Test::More 0.88;	# Because of done_testing();

use constant WANT_VERSION	=>
"App::AckX::Preflight $App::AckX::Preflight::VERSION
    $App::AckX::Preflight::COPYRIGHT
App::Ack $App::Ack::VERSION
    $App::Ack::COPYRIGHT
Perl $^V";

is xqt( '-version' ), WANT_VERSION, 'Version';

is xqt( '-e', q<'print "Hello, world.\\n"'> ), 'Hello, world.', 'Hello, world.';

done_testing;

sub xqt {
    my @arg = @_;
    my $rslt = `$^X t/execute @arg`;
    chomp $rslt;
    return $rslt;
}

1;

# ex: set textwidth=72 :
