package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use File::Temp;
use Test2::V0;

use constant IS_WINDOWS => App::AckX::Preflight->IS_WINDOWS();
use constant EXEC_IGNORED	=> "--dispatch=exec ignored under $^O";
use constant WANT_VERSION	=>
"App::AckX::Preflight $App::AckX::Preflight::VERSION
    $App::AckX::Preflight::COPYRIGHT
App::Ack $App::Ack::VERSION
    $App::Ack::COPYRIGHT
Perl $^V";

my $quote = IS_WINDOWS ? q<"> : q<'>;

is xqt( '-version' ), WANT_VERSION, 'spawn Version';

# NOTE in the xqt() call the Perl string has to be quoted twice so that
# it will still be quoted when interpolated into qx//.
is xqt( '-le', "${quote}print q/Hello, world./$quote" ), 'Hello, world.',
    'spawn Hello, world.';

SKIP: {
    IS_WINDOWS
	and skip EXEC_IGNORED, 1;

    is xqt( qw{ --dispatch=exec -le }, "${quote}print q/Hello, sailor!/$quote" ),
	'Hello, sailor!', 'exec Hello, sailor!';
}

# NOTE in the xqto() call the Perl string does NOT have to be quoted
# twice because it is passed to either a multi-argument system() or
# IPC::Cmd::run().
is xqto( qw{ -le }, 'print q/Hello, world./' ),
    '--OUT: Hello, world.',
    'spawn Hello, world via --OUT';

SKIP: {
    IS_WINDOWS
	and skip EXEC_IGNORED, 1;

    is xqto( qw{ --dispatch=exec -le }, 'print q/Hello, sailor!/' ),
	'--OUT: Hello, sailor!', 'exec Hello, sailor! via --OUT';
}

done_testing;

# NOTE this business of asking an external Perl script to run a command
# seems redundant, but if --dispatch=exec is in force the script running
# the command exits.

sub xqt {
    my @arg = @_;
    my $rslt = `$^X t/execute.PL @arg`;
    chomp $rslt;
    return $rslt;
}

sub xqto {
    my @arg = @_;
    my $temp = File::Temp->new();
    system { $^X } $^X, 't/execute.PL', '--OUT', $temp->filename(), @arg;
    seek $temp, 0, 0;
    my $rslt = do {
	# Localize $/ inside do() because chomp relies on $/
	local $/ = undef;
	'--OUT: ' . <$temp>;
    };
    # Not chomp(), because of \r\n under Windows.
    $rslt =~ s/ \s+ \z //smx;
    return $rslt;
}

1;

# ex: set textwidth=72 :
