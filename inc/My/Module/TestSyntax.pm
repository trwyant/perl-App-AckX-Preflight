package My::Module::TestSyntax;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Util qw{
    :croak
    :module
    :syntax
    __load_module
    __guess_encoding
    ACK_FILE_CLASS
    EMPTY_STRING
};
use Exporter qw{ import };
use Scalar::Util qw{ blessed };
use Test2::V0;

our $VERSION = '0.000_048';

our @EXPORT = ( qw{
	layers
	setup_slurp
	setup_syntax
	slurp
	ACK_FILE_CLASS
    },
    map { @{ $App::AckX::Preflight::Util::EXPORT_TAGS{$_} } } qw{ module
    syntax },
);

__load_module( MODULE_FILE_MONKEY );
__load_module( ACK_FILE_CLASS );

my %default_slurp_opt;
my $file_monkey_rslt;
my @layers;

sub layers {
    diag 'File handle PerlIO layers:';
    diag "    $_" for @layers;
    return;
}

sub setup_slurp {
    my %arg = @_;

    my $type = delete $arg{type}
	or __die_hard( 'Type required' );
    my $ext = delete $arg{extension}
	or __die_hard( 'Extension required' );
    $default_slurp_opt{type} = $type;
    $App::Ack::mappings{$type} = [
	App::Ack::Filter::Extension->new( ref $ext ? @{ $ext } : $ext ),
    ];

    if ( defined( my $enc = delete $arg{encoding} ) ) {
	$default_slurp_opt{encoding} = $enc;
    }

    keys %arg
	and __die_hard( 'Unsupported keys ', join ', ', map { "'$_'" }
	sort keys %arg );

    return;
}

sub setup_syntax {
    my ( %config ) = @_;
    my $caller = caller;
    my $syntax = $caller->SYNTAX_FILTER();
    my @monkey_work;
    if ( defined( my $enc = $default_slurp_opt{encoding} ) ) {
	my $out_enc = $enc =~ m/ \A guess \z /smxi ? 'utf-8' : $enc;
	push @monkey_work,
	[ MODULE_FILE_MONKEY, {
		output_encoding	=> $out_enc,
	    },
	],
	[ 'App::AckX::Preflight::Encode', {
		encoding	=> {
		    type	=> {
			$default_slurp_opt{type} => $enc,
		    },
		},
	    }
	],
    }
    $file_monkey_rslt = MODULE_FILE_MONKEY->import( [
	    @monkey_work,
	    [ $syntax, \%config ],
	],
    );
    $syntax->__post_open( \%config );
    return;
}

sub slurp {
    my ( $file, $opt ) = @_;
    $opt ||= {};
    my $encoding = $opt->{encoding} //
	$default_slurp_opt{encoding} //
	EMPTY_STRING;
    my $tell = $opt->{tell} // $default_slurp_opt{tell} // 0;
    my $caller = caller;
    my $fh;
    if ( blessed( $file ) ) {
	$fh = $file->open()
	    or die "@{[ ref $file ]}->open() failed: $!\n";
    } else {
	if ( $encoding =~ m/ \A guess \z /smxi ) {
	    open my $fh, '<', $file
		or die "Failed to open file: $!\n";
	    $encoding = __guess_encoding( $fh );
	}
	$encoding ne EMPTY_STRING
	    and $encoding = ":encoding($encoding)";
	my $syntax = $caller->SYNTAX_FILTER;
	open $fh, "<$encoding", $file
	    or die "Failed to open file: $!\n";
	# This has to be done separately or the UTF8 method does not
	# trigger correctly. If the file is opened
	# "<$encoding:via(...)", the UTF8 method gets passed a false
	# value.
	binmode $fh, "via($syntax)"
	    or die "Failed to binmode via($syntax): $!\n";
    }

    @layers = PerlIO::get_layers( $fh );

    my $rslt;
    local $_;	# while (<>) does not localize $_
    while ( <$fh> ) {
	s/ \s+ \z //smx;
	my @leader;
	push @leader, sprintf '%4d', $.;
	$tell
	    and push @leader, sprintf '%6d', tell $fh;
	$rslt .= $_ eq '' ? "@leader:\n" : "@leader: $_\n";
    }
    if ( blessed( $file ) ) {
	$file->close();
    } else {
	close $fh;
    }
    return $rslt;
}

1;

__END__

=head1 NAME

My::Module::TestSyntax - Test syntax filters

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::TestSyntax;
 
 print slurp( $file_name );

=head1 DESCRIPTION

This Perl module contains support procedures for testing syntax filters.
It is B<private> to the C<App-AckX-Preflight> distribution, and may be
altered or retracted without notice. Documentation is a convenience of
the author, not a commitment to the user. Void where prohibited.

=head1 SUBROUTINES

This module exports the following subroutines:

=head2 layers

When called this subroutine displays the L<PerlIO|PerlIO> layers in
effect after the last file open was performed as test diagnostics.

=head2 setup_slurp

 setup_slurp(
   type      => 'perl',
   extension => [ qw{ PL pm t } ],
   encoding  => 'utf-8',
 );

This subroutine configures the test. The arguments are key-value pairs,
with the fillowing arguments being supported:

=over

=item * C<'type'>

This is the F<ack> type being tested. The F<ack> type system will be
configured for this type.

This argument is required.

=item * C<'extension'>

Files having these extensions are recognized as being the type under
test. The value can be either a string or a reference to an array of
strings.

This argument is required, and it is the only F<ack> file type filter
supported.

=item * C<'encoding'>

The encoding of the file type.

This argument is optional.

=back

=head2 setup_syntax

 setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_COMMENT ] );

This subroutine sets up the syntax filter with the given configuration.

The caller is expected to have defined C<SYNTAX_FILTER> to the syntax
filter being used.

=head2 slurp

 print slurp( $file_name, \%options );

This subroutine reads the given file, and returns its contents with line
numbers prefixe.

The \%option hash is itself optional. The supported keys are:

=over

=item C<{tell}> - if true, adds the file position B<after> the read to the output.

=back

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax> and
friends.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
