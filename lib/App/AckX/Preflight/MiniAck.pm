package App::AckX::Preflight::MiniAck;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{ :all };
use File::Find ();
use File::Spec;

our $VERSION = '0.000_044';

__load_module( ACK_FILE_CLASS );

sub run {
    ( undef, local @ARGV ) = @_;

    $DB::single = 1;

    # Ack parses everything I want, and some more besides. So I can just
    # pick it out of Ack's options hash.
    my $opt = __load_ack_config();

    $opt->{heading} //= -t STDOUT;

    delete $opt->{h}
	and $opt->{H} = 0;

    defined $opt->{regex}
	or $opt->{regex} = shift @ARGV;

    @ARGV
	or push @ARGV, File::Spec->curdir();

    my $multi_file = @ARGV != 1 || -d $ARGV[0];

    defined $opt->{H}
	or $opt->{H} = $multi_file;

    exists $opt->{break}
	or $opt->{break} = ( $multi_file && -t STDOUT );

    # The POD says that ack always selects files specified explicitly.
    my %explicit = map { $_ => 1 } @ARGV;

    my @want_file;

    File::Find::find(
	{
	    wanted	=> sub {

		my $file = ACK_FILE_CLASS->new( $File::Find::name );

		if ( -d ) {
		    foreach my $filter ( @{ $opt->{idirs} } ) {
			$filter->filter( $file )
			    or next;
			$File::Find::prune = 1;
			return;
		    }
		    return;
		}

		# The POD says that ack always selects files specified
		# explicitly.
		if ( $explicit{$File::Find::name} ) {
		    push @want_file, $File::Find::name;
		    return;
		}

		-B _
		    and return;

		$opt->{ifiles}->filter( $file )
		    and return;
		if ( $opt->{filters} ) {
		    foreach my $filter( @{ $opt->{filters} } ) {
			$filter->filter( $file )
			    or next;
			push @want_file, $File::Find::name;
			return;
		    }
		} else {
		    push @want_file, $File::Find::name;
		}

		return;
	    },
	    no_chdir	=> 1,
	},
	@ARGV,
    );

    $opt->{sort_files}
	and @want_file = sort @want_file;

    my $regex = do {
	local $_ = $opt->{regex};

	$opt->{Q}
	    and $_ = quotemeta $_;

	if ( $opt->{w} ) {
	    if ( m/ \A \\ [wd] /smx ) {
		# We're good.
	    } elsif ( m/ \A \w /smx ) {
		substr $_, 0, 0, "\\b";
	    }
	    if ( m/ \\ [wd] \z /smx ) {
		# We're good
	    } elsif ( m/ ( \\* ) \w \z /smx ) {
		# It's only a word character if it is not escaped.
		length( $1 ) % 2
		    or $_ .= "\\b";
	    }
	}

	$opt->{i}
	    and substr $_, 0, 0, '(?i)';
	eval "sub { m/$_/ }"	## no critic (ProhibitStringyEval)
	    or __die(
	    "--match='$opt->{regex} produced invalid regexp m/$_/" );
    };

    my $exit_status = 1;

    foreach my $path ( @want_file ) {
	my $file = ACK_FILE_CLASS->new( $path );

	my $fh = $file->open();

	local $_ = undef;

	while ( <$fh> ) {
	    $regex->()
		or next;

	    $exit_status = 0;

=begin comment

	    if ( $opt->{heading} ) {
		$header_printed ||= do {
		    $opt->{break} and say '';
		    say $path;
		    1;
		};

		print $opt->{H} ? "$.:$_" : $_;
	    } else {
		print $opt->{H} ? "$path:$.:$_" : "$path:$_";
	    }

=end comment

=cut

	    not $exit_status
		and $opt->{break}
		and say '';

	    $opt->{heading}
		and $opt->{H}
		and say $path;

	    my @line;
	    $opt->{H}
		and push @line, $path;
	    $multi_file
		and push @line, $.;
	    print join ':', @line, $_;

	}

	$file->close();
    }

    return $exit_status;
}

1;

__END__

=head1 NAME

App::AckX::Preflight::MiniAck - Provide minimal ack functionality without shelling out.

=head1 SYNOPSIS

 $ ackxp --dispatch=none ...

This module is not directly invoked by the user.

=head1 DESCRIPTION

This module should be considered private to the C<App-AckX-Preflight>
package. If you think you would like to make use of it, let me know so I
can beef up the caveats.

This module provides a subset of the F<ack> functionality without
shelling out to F<ack> itself. It will go away if I can ever figure out
how to do that with F<ack> itself. And no, C<do()> doesn't.

This module was really written so that I can get test coverage
information on code that normally only gets executed (if at all) by
getting hot-patched into F<ack> itself. The incentive for coverage
testing was a refactor of the hot patch functionality, and I wanted to
find out what was truly dead code and what was live code that
C<testcover> could not find.

The F<ack> configuration is picked up, but this can not be overridden
from the command line. The only configuration used by this module is the
'ignore' configuration (C<--ignore-dir>, C<--no-ignore-dir>, and
C<--ignore-file>).

The following F<ack> command line options are processed by this module:

    --break --no-break
    --env --noenv
    -h --no-filename
    -H --with-filename
    -i --ignore-case
    =I --no-ignore-case
    --match
    -Q --literal
    --sort-files
    -t --type
    -T
    -w --word-regexp

In addition, all F<ackxp> options are processed.

No F<ack> functionality is provided unless specifically documented
above. Specifically, there is no match highlighting.

=head1 METHODS

This class supports the following public methods:

=head2 run

This static method takes as its arguments the command line as modified
by L<App::AckX::Preflight|App::AckX::Preflight>. It performs its search,
and returns C<0> if any matches were found, or C<1> if not.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>

L<ack|ack>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
