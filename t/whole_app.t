package main;

use 5.008008;

use strict;
use warnings;

use File::Temp;
use Test2::V0;

use constant ACKXP_STANDALONE	=> 'ackxp-standalone';

-x $^X
    or plan skip_all => "Somethig strange is going on. \$^X ($^X) is not executable.";

if ( need_to_regenerate_ackxp_standalone() ) {
    note 'Regenerating ', ACKXP_STANDALONE;
    system { 'perl' } qw{ perl -Mblib tools/squash -o }, ACKXP_STANDALONE;
}

foreach my $app ( 'blib/script/ackxp', ACKXP_STANDALONE ) {
    -x $app
	or next;

    diag "Testing $app";

    xqt( $app, qw{ --noenv --syntax code -w Wyant lib/ }, <<'EOD' );
lib/App/AckX/Preflight.pm:29:    $COPYRIGHT = 'Copyright (C) 2018-2022 by Thomas R. Wyant, III';
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
lib/App/AckX/Preflight.pm:29:    $COPYRIGHT = 'Copyright (C) 2018-2022 by Thomas R. Wyant, III';
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
    my $stdout = _back_tick( @arg );
    @_ = ( $stdout, $want, $title );
    goto \&is;
}

sub _back_tick {
    my @cmd = @_;

    my $options = {};

    # When you care enough to steal the very best.

## VERBATIM BEGIN https://metacpan.org/dist/ack/source/t/Util.pm?raw=1

    my ( @stdout, @stderr );

    if ( is_windows() ) {
        ## no critic ( InputOutput::ProhibitTwoArgOpen )
        ## no critic ( InputOutput::ProhibitBarewordFileHandles )
        require Win32::ShellQuote;
        # Capture stderr & stdout output into these files (only on Win32).
        my $tempdir = File::Temp->newdir;
        my $catchout_file = File::Spec->catfile( $tempdir->dirname, 'stdout.log' );
        my $catcherr_file = File::Spec->catfile( $tempdir->dirname, 'stderr.log' );

        open(SAVEOUT, '>&STDOUT') or die "Can't dup STDOUT: $!";
        open(SAVEERR, '>&STDERR') or die "Can't dup STDERR: $!";
        open(STDOUT, '>', $catchout_file) or die "Can't open $catchout_file: $!";
        open(STDERR, '>', $catcherr_file) or die "Can't open $catcherr_file: $!";
        my $cmd = Win32::ShellQuote::quote_system_string(@cmd);
        if ( my $input = $options->{input} ) {
            my $input_command = Win32::ShellQuote::quote_system_string(@{$input});
            $cmd = "$input_command | $cmd";
        }
        system( $cmd );
        close STDOUT;
        close STDERR;
        open(STDOUT, '>&SAVEOUT') or die "Can't restore STDOUT: $!";
        open(STDERR, '>&SAVEERR') or die "Can't restore STDERR: $!";
        close SAVEOUT;
        close SAVEERR;
        @stdout = read_file($catchout_file);
        @stderr = read_file($catcherr_file);
    }
    else {
        my ( $stdout_read, $stdout_write );
        my ( $stderr_read, $stderr_write );

        pipe $stdout_read, $stdout_write
            or die "Unable to create pipe: $!";

        pipe $stderr_read, $stderr_write
            or die "Unable to create pipe: $!";

        my $pid = fork();
        if ( $pid == -1 ) {
            die "Unable to fork: $!";
        }

        if ( $pid ) {
            close $stdout_write;
            close $stderr_write;

            while ( $stdout_read || $stderr_read ) {
                my $rin = '';

                vec( $rin, fileno($stdout_read), 1 ) = 1 if $stdout_read;
                vec( $rin, fileno($stderr_read), 1 ) = 1 if $stderr_read;

                select( $rin, undef, undef, undef );

                if ( $stdout_read && vec( $rin, fileno($stdout_read), 1 ) ) {
                    my $line = <$stdout_read>;

                    if ( defined( $line ) ) {
                        push @stdout, $line;
                    }
                    else {
                        close $stdout_read;
                        undef $stdout_read;
                    }
                }

                if ( $stderr_read && vec( $rin, fileno($stderr_read), 1 ) ) {
                    my $line = <$stderr_read>;

                    if ( defined( $line ) ) {
                        push @stderr, $line;
                    }
                    else {
                        close $stderr_read;
                        undef $stderr_read;
                    }
                }
            }

            waitpid $pid, 0;
        }
        else {
            close $stdout_read;
            close $stderr_read;

            if (my $input = $options->{input}) {
                _check_command_for_taintedness( @{$input} );
                open STDIN, '-|', @{$input} or die "Can't open STDIN: $!";
            }

            open STDOUT, '>&', $stdout_write or die "Can't open STDOUT: $!";
            open STDERR, '>&', $stderr_write or die "Can't open STDERR: $!";

            exec @cmd;
        }
    } # end else not Win32
## VERBATIM END

    return join '', @stdout;
}

## VERBATIM BEGIN https://metacpan.org/dist/ack/source/t/Util.pm?raw=1
sub is_windows {
    return $^O eq 'MSWin32';
}
## VERBATIM END

## VERBATIM BEGIN https://metacpan.org/dist/ack/source/t/Util.pm?raw=1
sub read_file {
    my $filename = shift;

    open( my $fh, '<', $filename ) or die "Can't read $filename: \n";
    my @lines = <$fh>;
    close $fh or die;

    return wantarray ? @lines : join( '', @lines );
}
## VERBATIM END

1;

# ex: set textwidth=72 :
