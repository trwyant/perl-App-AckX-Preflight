 package App::AckX::Preflight::Plugin::Encode;

use 5.010001;

use strict;
use warnings;
use parent qw{ App::AckX::Preflight::Plugin };

use App::AckX::Preflight::Util qw{
    __check_encoding
    :croak
    @CARP_NOT
};

our $VERSION = '0.000_046';

use constant DISPATCH_PRIORITY	=> 100;

sub __options {
    return( qw{ encoding=s@ } );
}

sub __process {
    my ( undef, $aaxp, $opt ) = @_;

    defined $opt->{$_} or delete $opt->{$_} for keys %{ $opt };

    keys %{ $opt }
	or return;

    $opt->{encoding} ||= [];

    foreach ( @{ $opt->{encoding} } ) {
	my ( $encoding, $filter, $arg ) = split /:/, $_, 3;
	__check_encoding( $encoding );
	defined $filter
	    or __die( 'No --encoding filter specified' );
	defined $arg
	    or ( $filter, $arg ) = ( is => $filter );
	$_ = [ $encoding, $filter, $arg ];
    }

    $aaxp->__file_monkey( 'App::AckX::Preflight::Encode', $opt );

    return;
}


sub __wants_to_run {
    my ( undef, $opt ) = @_;
    return !! $opt->{encoding};
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin::Encode - Provide --encoding for ackxp

=head1 SYNOPSIS

None. The user has no direct interaction with this module.

=head1 DESCRIPTION

This L<App::AckX::Preflight|App::AckX::Preflight> plug-in provides the
ability to specify the encoding for a specific F<ack> file type.

This plug-in recognizes and processes the following options:

=head2 --encoding

 --encoding utf-8:type:perl
 --encoding cp1252:is:windows.bat

This option specifies the encoding to be applied to a specific file or
class of files. The value is three colon-delimited values: the encoding,
the rule, and the argument for the rule, which varies based on the rule.

Valid rules are:

=over

=item type

This rule specifies an F<ack> file type. The argument is the specific
type.

=item is

This rule specifies an individual file. The argument is the path to the
file.

=back

B<Note> that although the syntax looks like that of an F<ack> filter
rule, L<App::Ack::Filter|App::Ack::Filter> objects are B<not> used to
match encodings to files.

=head1 METHODS

This class provides no additional methods. However, the following
overrides may be of interest.

=head2 DISPATCH_PRIORITY

This is set to C<100>.

This plug-in works by getting input files opened C<:encoding(...)>. Its
dispatch priority must be high enough to ensure that
L<App::AckX::Preflight::FileMonkey|App::AckX::Preflight::FileMonkey>
processes it before any other code that adds L<PerlIO|PerlIO> layers to
the file handle.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

L<App::AckX::Preflight::FileMonkey|App::AckX::Preflight::FileMonkey>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
