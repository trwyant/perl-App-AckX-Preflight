package My::Module::Test;

use 5.008008;

use strict;
use warnings;

use Carp;
use Cwd ();

our $VERSION = '0.000_001';

use Exporter ();

{
    my %special = (

	'-noexec'	=> sub {

	    require App::AckX::Preflight;

	    no warnings qw{ redefine };

	    *App::AckX::Preflight::__execute = sub {
		my ( undef, @arg ) = @_;
		return @arg;
	    };

	    return;
	},

	'-search-test'	=> sub {

	    require Module::Pluggable::Object;

	    my $old_new = \&Module::Pluggable::Object::new;

	    no warnings qw{ redefine };

	    *Module::Pluggable::Object::new = sub {
		my ( $class, %opt ) = @_;
		push @{ $opt{search_dirs} ||= [] }, Cwd::abs_path( 't/lib' );
		return $old_new->( $class, %opt );
	    };

	    return;
	},
    );

    sub import {
	my @arg = @_;
	@_ = ();
	while ( @arg ) {
	    my $p = shift @arg;
	    if ( my $code = $special{$p} ) {
		$code->( \@arg );
	    } else {
		push @_, $p;
	    }
	}
	goto &Exporter::import;
    }
}




1;

__END__

=head1 NAME

My::Module::Test - Test set-up for App::AckX::Preflight

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test qw{ -noexec -search-test };

=head1 DESCRIPTION

This Perl module does test setup for
L<App::AckX::Preflight|App::AckX::Preflight>. It does not export
anything at the moment, but rather mungs things for testing.

=head1 EXPORTS

The following exports are possible:

=head2 -noexec

If this tag is seen, C<App::AckX::Preflight::__execute()> is replaced by
code that simply returns its arguments.

=head2 -search-test

If this tag is seen, C<Module::Pluggable::Object::new()> is replaced by
code that adds F<t/lib> to its C<{search_dirs}> argument, creating it if
necessary. The resultant arguments are dispatched to the original
C<new()>.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

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
