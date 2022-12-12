package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use File::Temp;
use Test2::V0;

use constant WANT_VERSION	=>
"App::AckX::Preflight $App::AckX::Preflight::VERSION
    $App::AckX::Preflight::COPYRIGHT
App::Ack $App::Ack::VERSION
    $App::Ack::COPYRIGHT
Perl $^V";

is xqt( '-version' ), WANT_VERSION, 'spawn Version';

# NOTE in the xqt() call the Perl string has to be quoted twice so that
# it will still be quoted when interpolated into qx//.
is xqt( '-le', q<'print "Hello, world."'> ), 'Hello, world.',
    'spawn Hello, world.';

is xqt( qw{ --exec -le }, q<'print "Hello, sailor!"'> ),
    'Hello, sailor!', 'exec Hello, sailor!';

# NOTE in the xqto() call the Perl string does NOT have to be quoted
# twice because it is passed to either a multi-argument system() or
# IPC::Cmd::run().
is xqto( qw{ -le }, 'print "Hello, world."' ),
    '--output: Hello, world.',
    'spawn Hello, world via --output';

is xqto( qw{ --exec -le }, 'print "Hello, sailor!"' ),
    '--output: Hello, sailor!', 'exec Hello, sailor! via --output';

done_testing;

sub xqt {
    my @arg = @_;
    my $rslt = `$^X t/execute.PL @arg`;
    chomp $rslt;
    return $rslt;
}

sub xqto {
    my @arg = @_;
    my $temp = File::Temp->new();
    system { $^X } $^X, 't/execute.PL', '--output', $temp->filename(), @arg;
    seek $temp, 0, 0;
    my $rslt = do {
	# Localize $/ inside do() because chomp relies on $/
	local $/ = undef;
	'--output: ' . <$temp>;
    };
    chomp $rslt;
    return $rslt;
}

1;

# ex: set textwidth=72 :
