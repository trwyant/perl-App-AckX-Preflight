package App::AckX::Preflight::FileMonkey;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{
    :croak
    __json_decode
    __load_module
    __set_sub_name
    ACK_FILE_CLASS
    DEFAULT_OUTPUT
    @CARP_NOT
};
use JSON;
use Scope::Guard ();

our $VERSION = '0.000_045';

my @LAYERS;
my $OPT;
my $SPEC;

sub import {
    my ( $class, $arg ) = @_;
    $arg //= [];

    my $spec = ref $arg ? $arg : eval {
	    __json_decode( $arg );
	}
	|| __die_hard( "Failed to parse '$arg' as JSON" );
    my %rslt;
    foreach my $item ( @{ $spec } ) {
	__load_module( $item->[0] )
	    or __die( "Failed to load $item->[0]: $@" );
	$rslt{$item->[0]} = $item->[0]->__setup( $item->[1] );
    }

    $SPEC = $spec;

    $class->__hot_patch();

    defined wantarray
	or return;

    return %rslt;

}

sub __hot_patch {

    state $open;

    $open
	and return;

    __load_module( ACK_FILE_CLASS )
	or __die_hard( sprintf 'Can not load %s', ACK_FILE_CLASS );

    $open = ACK_FILE_CLASS->can( 'open' )
	or __die_hard( sprintf '%s does not implement open()', ACK_FILE_CLASS );

    my $code = sub {
	# NOTE that $self is an App::Ack::File object, which we patched
	# over that class' open() method.
	my ( $self ) = @_;

	my $fh = $open->( $self );

	# If the caller is a resource or a filter we're not opening for
	# the main scan. Just use the normal machinery.
	my $caller = caller;
	if ( defined $caller ) {
	    foreach my $cls ( ACK_FILE_CLASS, qw{ App::Ack::Filter } ) {
		$caller->isa( $cls )
		    and return $fh;
	    }
	}

	my @binmode;
	foreach my $item ( @{ $SPEC } ) {
	    push @binmode, $item->[0]->__post_open( $item->[1], $fh, $self );
	}

	# We have to defer the binmode calls until all __post_open() calls
	# have been made because:
	# * If one of them wants :encoding(...) and another uses a
	#   filter that calls ->firstliney() the call will fail because
	#   it uses sysread().
	# * If one of them wants :via(...) it has to come after
	#   :encoding(...) (if any) or the :via(...) code sees
	#   un-decoded data.
	foreach ( @binmode ) {
	    binmode $fh, $_
		or __die( "Failed to do binmode \$fh, $_ on ",
		$self->name(), ": $!" );
	}

	@LAYERS = PerlIO::get_layers( $fh );

	if ( $OPT->{verbose} ) {
	    warn "#\$ PerlIO layers:\n";
	    warn "#\$   $_\n" for @LAYERS;
	}

	# Return the handle
	return $fh;

    };

    no warnings qw{ redefine };	## no critic (ProhibitNoWarnings)
    no strict qw{ refs };

    my $repl = join '::', ACK_FILE_CLASS, 'open';

    *$repl = __set_sub_name( open => $code );

    return;
}

sub __layers {
    return @LAYERS;
}

sub __post_open {}

sub __setup {
    my ( undef, $opt ) = @_;
    $OPT = $opt;

    my $wantarray = ( caller 1 )[5];

    # Redirect STDOUT to a file if needed. We make no direct use of the
    # returned object, but hold it because its destructor undoes the
    # redirect on scope exit.
    # NOTE that we rely on the fact that destructors are NOT run when an
    # exec() is done.
    my %rslt;
    {
	my $output = $opt->{output};
	my $output_encoding = $opt->{output_encoding};
	if ( $output ne DEFAULT_OUTPUT ) {
	    $wantarray
		and $rslt{output} = _restore_stdout_when_done();
	    close STDOUT;
	    my $mode = defined $output_encoding ?
		">:encoding($output_encoding)" : '>';
	    open STDOUT, $mode, $output
		or __die( "Failed to re-open STDOUT to $output: $!" );
	} elsif ( defined $output_encoding ) {
	    $wantarray
		and $rslt{output} = _restore_stdout_when_done();
	    # FIXME does this work in Windows?
	    # :raw to ditch any previous encodings.
	    binmode STDOUT, ":raw:encoding($output_encoding)"
		or __die(
		"Failed to set STDOUT encoding to '$output_encoding': $!" );
	}
    }

    return \%rslt;
}

sub _restore_stdout_when_done {
    open my $clone, '>&', \*STDOUT	## no critic (RequireBriefOpen)
	or __die( "Failed to dup STDOUT: $!" );
    return Scope::Guard->new( sub {
	    close STDOUT;
	    open STDOUT, '>&', $clone
		or __die( "Failed to restore STDOUT: $!" );
	    return;
	},
    );
}

1;

__END__

=head1 NAME

App::AckX::Preflight::FileMonkey - Manage the App::Ack input streams.

=head1 SYNOPSIS

Not directly invoked by the user.

=head1 DESCRIPTION

B<This Perl module is private to the C<App-AckX-Preflight> package.> It
can be changed or revoked without warning. Documentation is for the
benefit of the author, and does not constitute an API contract. Void
where prohibited.

This Perl module modifies C<ack>'s input streams as needed by any
relevant L<App::AckX::Preflight|App::AckX::Preflight> functionality. It
does so by monkey-patching the C<open()> method in
L<App::Ack::File|App::Ack::File> (or similar) to introduce I/O layers as
needed.

=head1 METHODS

This class supports the following package-private methods:

=head2 import

This static method is called when the module is loaded. It takes one
argument, which is either an C<ARRAY> reference or the equivalent
JSON-encoded string containing configuration information for
C<App::Ack::Preflight::*>. This array reference must look like this:

 [
   [ <module-name>, <configuration-data> ],
   ...
 ]

The C<< <module-name> >> is the name of the C<App::AckX::Preflight>
module that provides the requested functionality. The
C<< <configuration-data> >> are a hash reference which is (eventually)
passed to the module's C<__configure()> method.

This method stashes the configuration data, then calls
L<__hot_patch()|/__hot_patch>, and returns.

This method returns nothing.

=head2 __hot_patch

On the first call this method saves a reference to the
L<App::Ack::File|App::Ack::File> C<open()> method, and replaces it with
its own.

The new method calls the original C<open()> on its argument, retaining
the file handle. It then iterates over the configuration data, calling
C<__configure()> on the classes specified.

The call to C<__configure()> receives two arguments besides the
invocant: the configuration hash, the file handle, and the
L<App::Ack::File|App::Ack::File> object.

It is expected that the C<__configure()> methods will provide their
functionality via an I/O layer. But the methods B<must not> install this
layer themselves. Instead, they B<must> return the desired second
C<binmode()> arguments they want. If none is wanted, they B<must> return
nothing (i.e. simply return -- B<not> return C<undef>).

Last, the new method calls C<binmode()> as required, and returns the
file handle.

=head1 SEE ALSO

L<App::AckX::Preflight::Syntax|App::AckX::Preflight::Syntax>, which
makes use of this interface.

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
