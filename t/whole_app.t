package main;

use 5.008008;

use strict;
use warnings;

use File::Temp;
use IPC::Cmd ();
use Test2::V0;

{
    AmigaOS	=> 1,
    'RISC OS'	=> 1,
    VMS		=> 1,
}->{$^O}
    and plan skip_all => "Fork command via -| does not work under $^O";

use constant ACKXP_STANDALONE	=> 'ackxp-standalone';

-x $^X
    or plan skip_all => "Somethig strange is going on. \$^X ($^X) is not executable.";

=begin comment

if ( need_to_regenerate_ackxp_standalone() ) {
    note 'Regenerating ', ACKXP_STANDALONE;
    system { 'perl' } qw{ perl -Mblib tools/squash -o }, ACKXP_STANDALONE;
}

foreach my $app ( 'blib/script/ackxp', ACKXP_STANDALONE ) {

=end comment

=cut

# FIXME building the standalone app is broken unless it also includes
# ack_standalone

foreach my $app ( [ $^X, qw{ -Mblib blib/script/ackxp } ] ) {
    -x $app->[0]
	or next;

    diag "Testing @{ $app }";

    xqt( $app, qw{ --noenv --syntax code -w Wyant lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:17:our $COPYRIGHT = 'Copyright (C) 2018-2022 by Thomas R. Wyant, III';
EOD

    xqt( $app, qw{ --noenv --syntax-match -syntax-type --syntax-wc t/data/perl_file.PL }, <<'EOD' );
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

    xqt( $app, qw{ --noenv --syntax code -file t/data/file lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:17:our $COPYRIGHT = 'Copyright (C) 2018-2022 by Thomas R. Wyant, III';
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
    my ( $app, @arg ) = @_;
    my $want = pop @arg;
    my $out = File::Temp->new();
    splice @arg, 0, 0, @{ $app }, '--output', $out->filename();
    my $title = "@arg";

    local $! = 0;

=begin comment

    my $exst = system { $arg[0] } @arg;
    $exst and do {
	@_ = (
	    sprintf '%s: system() failed:%s $? is %s',
		$title,
		( $! ? " \$! is $!," : '' ),
		exit_code( $exst ),
	);
	goto &fail;
    };

=end comment

=cut

    my ( $ok, $errmsg, undef, $stdout, $stderr ) = IPC::Cmd::run(
	command => \@arg );

    unless ( $ok ) {
	@_ = "$title failed: error $errmsg";
	IPC::Cmd->can_capture_buffer()
	    and $_[0] .= "; stderr $stderr";
	goto &fail;
    }

    seek $out, 0, 0;

    local $/ = undef;

    local $/ = undef;	# Slurp
    @_ = ( scalar( <$out> ), $want, $title );
    goto &is;
}

sub exit_code {
    my ( $num ) = @_;
    $num == -1
	and return "Failed to execute command: $!";
    $num & 0x7F
	and return sprintf 'Child died with signal %s, %s coredump',
	    sig_num( $num ), $num & 0x80 ? 'with' : 'without';
    return sprintf 'Child exited with value %d', $num >> 8;
}

sub sig_num {
    my ( $num ) = @_;
    $num &= 0x7F;
    local $@ = undef;
    eval { require Config; 1 }
	or return sprintf '%d', $num;
    my @sig;
    @sig[ split / /, $Config::Config{sig_num} ] =
	split / /, $Config::Config{sig_name};
    return sprintf '%d ( SIG%s )', $num, $sig[$num];
}

1;

# ex: set textwidth=72 :
