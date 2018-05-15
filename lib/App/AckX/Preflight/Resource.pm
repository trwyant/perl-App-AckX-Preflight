package App::AckX::Preflight::Resource;

use 5.008008;

use strict;
use warnings;

use App::Ack::Resource;
use App::AckX::Preflight::Syntax;
use App::AckX::Preflight::Util qw{ @CARP_NOT };

our $VERSION = '0.000_012';

{

    sub App::Ack::Resource::__ackx_preflight__is_type {
	my ( $self, @type_list ) = @_;

	foreach my $type ( @type_list ) {
	    foreach my $f ( @{ $App::Ack::mappings{$type} || [] } ) {
		$f->filter( $self )
		    and return $type;
	    }
	}
	return;
    }

    my @normal_open = qw{
	App::Ack::Resource
	App::Ack::Filter
    };

    my $open = \&App::Ack::Resource::open;

    no warnings qw{ redefine };	## no critic (ProhibitNoWarnings)

    *App::Ack::Resource::open = sub {
	my ( $self ) = @_;

	# If the caller is a resource or a filter we're not opening for
	# the main scan. Just use the normal machinery.
	my $caller = caller;
	foreach my $class ( @normal_open ) {
	    $caller->isa( $class )
		and goto $open;
	}

	# Foreach of the syntax filter plug-ins
	foreach my $class ( App::AckX::Preflight::Syntax->__plugins() ) {

	    # See if this resource is of the type serviced by this
	    # module. If not, try the next.
	    $self->__ackx_preflight__is_type( $class->__handles_type() )
		or next;

	    # If we want everything we don't need the filter.
	    $class->__want_everything()
		and goto $open;

	    # Open the file, inserting the PerlIO::via module into the
	    # mix.
	    if ( !$self->{opened} ) {
		if ( open $self->{fh},
		    "<:via($class)",
		    $self->{filename}
		) {
		    $self->{opened} = 1;
		}
		else {
		    $self->{fh} = undef;
		}
	    }

	    return $self->{fh};
	}

	# If no syntax filter found, use the normal open() machinery.
	goto $open;
    };
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Resource - Enhance App::Ack::Resource

=head1 SYNOPSIS

 $ perl -MApp::AckX::Resource -S ack ...

=head1 DESCRIPTION

This Perl module enhances C<App::Ack::Resource> for use by the
C<App::AckX::Preflight> system.

=over

=back

=head1 METHODS

This class adds or modifies the following C<App::Ack::Resource> methods:

=head2 __appx_preflight__is_type

This new method takes one or more file types as arguments, and returns
the first type that matches the resource. If none match, nothing is
returned.

=head2 open

This method is patched over the original C<App::Ack::Resource> C<open()>
method.

It first determines by examining its caller whether F<ack> is
opening the file to execute a filter or to scan the file for matches. In
the former case the original C<open()> code is used to open the file.

Next, it examines the list of loaded modules looking for
C<App::AckX::Preflight::via::*> modules. For each one found, it checks
to see if the current resource is of any of the file types serviced by
that module. The first match causes the file to be opened with the
C<App::AckX::Preflight::via> module inserted as an I/O layer.

If no C<App::AckX::Preflight::via::*> modules match this resource, the
original C<open()> code is used to open the file.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

L<App::Ack::Resource|App::Ack::Resource>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
