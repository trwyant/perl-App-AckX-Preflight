package App::AckX::Preflight::FileMonkey;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{
    :croak
    __json_decode
    __load
    __set_sub_name
    ACK_FILE_CLASS
    @CARP_NOT
};
use JSON;

our $VERSION = '0.000_044';

my $SPEC;

sub import {
    my ( $class, $arg ) = @_;
    $arg //= [];

    my $spec = ref $arg ? $arg : eval {
	    __json_decode( $arg );
	}
	|| __die_hard( "Failed to parse '$arg' as JSON" );
    foreach my $item ( @{ $spec } ) {
	__load( $item->[0] )
	    or __die( "Failed to load $item->[0]: $@" );
    }

    $SPEC = $spec;

    $class->__hot_patch();

    return;

}

sub __hot_patch {

    state $open;

    $open
	and return;

    __load( ACK_FILE_CLASS )
	or __die_hard( sprintf 'Can not load %s', ACK_FILE_CLASS );

    $open = ACK_FILE_CLASS->can( 'open' )
	or __die_hard( sprintf '%s does not implement open()', ACK_FILE_CLASS );

    my $code = sub {
	my ( $self ) = @_;

	my $fh = $open->( $self );

	foreach my $item ( @{ $SPEC } ) {
	    $item->[0]->__setup( $item->[1], $fh, $self );
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
argument, which is a JSON-encoded string containing configuration
information for C<App::Ack::Preflight::*>. This must decode to an array
reference with the following structure:

 [
   [ <module-name>, <configuration-data> ],
   ...
 ]

The C<< <module-name> >> is the name of the C<App::AckX::Preflight>
module that provides the requested functionality. The
C<< <configuration-data> >> are a hash reference which is (eventually)
passed to the module's C<__configure()> method.

Once the argument is decoded, this method loads all the modules
specified (failing on a load error), and then calls the
L<__hot_patch()|/__hot_patch> method, passing it the configuration as a
hash reference.

This method returns nothing.

=head2 __hot_patch

This static method is passed a reference to the configuration data
described above under L<import()|/import>.

If this method has already been called, it does nothing.

On the first call this method saves a reference to the
L<App::Ack::File|App::Ack::File> C<open()> method, and replaces it with
its own.

The new method calls C<open()> on its argument, retaining the file
handle. It then iterates over the configuration data, calling
C<__configure()> on the classes specified.  It then returns the file
handle.

The call to C<__configure()> receives two arguments besides the
invocant: the configuration hash, the file handle, and the
L<App::Ack::File|App::Ack::File> object. The method can recover the
handle by calling C<open()> on the file object, since C<open()> is
idempotent.

It is expected that the C<__configure()> methods will provide their
functionality by calling C<binmode()> on the file handle. Mostly these
will install themselves using the C<:via:> interface, though encoding
support would obviously provide an C<:encoding()> layer.

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

Copyright (C) 2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
