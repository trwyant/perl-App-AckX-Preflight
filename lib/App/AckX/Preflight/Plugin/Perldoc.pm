package App::AckX::Preflight::Plugin::Perldoc;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Plugin;
use App::AckX::Preflight::Util qw{ SYNTAX_DOCUMENTATION };
use Config ();

our @ISA;

our $VERSION;

BEGIN {

    App::AckX::Preflight::Util->import(
	qw{
	    :all
	}
    );
    @ISA = qw{ App::AckX::Preflight::Plugin };

    $VERSION = '0.000_039';
}

# IF we have been requested, request default syntax of 'doc'.
sub __default_arg {
    my ( undef, $opt ) = @_;
    $opt->{perldoc}
	and return ( '--syntax', SYNTAX_DOCUMENTATION );
    return;
}

sub __options {
    return( qw{ perldoc! } );
}

sub __process {
    my ( undef, undef, $opt ) = @_;

    # Unless we actually have a --perldoc option, we have nothing to do.
    $opt->{perldoc}
	or return;

    # Append the Perl directories to the argument list
    push @ARGV,
	@INC,
	grep { defined( $_ ) && $_ ne '' && -d } map { $Config::Config{$_} }
	qw{
	    archlibexp
	    privlibexp
	    sitelibexp
	    vendorlibexp
	}
    ;

    return 1;
}


1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Perldoc - Provide --perldoc for ackxp

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to search the installed Perl modules in a manner similar to
L<App:Perldoc::Search|App:Perldoc::Search>.

In order to get this functionality, the user must specify the
C<--perldoc> command line option.

If C<--perldoc> is specified, command line option
C<--syntax=documentation> is provided by default unless some C<--syntax>
option is specified explicitly. The user who does not want syntax
filtering with this plug-in can specify C<--syntax=none>.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

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
