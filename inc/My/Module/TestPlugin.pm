package My::Module::TestPlugin;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{ HASH_REF __getopt_for_plugin };
# use Carp;
use Exporter qw{ import };

our @EXPORT_OK = qw{ prs xqt };

our @EXPORT = @EXPORT_OK;

our $VERSION = '0.000_037';

sub prs {
    local @ARGV = @_;
    my $caller = caller;
    my $opt = __getopt_for_plugin( $caller->CLASS() );
    return ( $opt, @ARGV );
}

sub xqt {
    local @ARGV = @_;
    my $caller = caller;
    my $aaxp = 'App::AckX::Preflight' eq ref $ARGV[0] ?
	shift @ARGV :
	App::AckX::Preflight->new();
    my $opt = HASH_REF eq ref $ARGV[0] ? shift @ARGV : {};
    $caller->CLASS()->__process( $aaxp, $opt );
    return ( @ARGV );
}

1;

__END__

=head1 NAME

My::Module::TestPlugin - Support for unit testing plugins.

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::TestPlugin;

=head1 DESCRIPTION

This Perl module contains support code for testing
L<App::AckX::Preflight|App::AckX::Preflight> plugins.

This module is B<private> to the C<App-AckX-Preflight> distribution, and
can and will be modified or retracted without notice.

=head1 SUBROUTINES

The following subroutines are exported by default:

=head2 prs

 ( my $opt, @argv ) = prs( @argv );

This subroutine is just a convenience wrapper for
L<__getopt_for_plugin()|App::AckX::Preflight::Util/__getopt_for_plugin>.
The plugin class name is obtained from manifest constant C<CLASS>,
defined in the caller. Arguments if any are loaded into a localized
@ARGV. The return is the options hash and anything that was left in
C<@ARGV> after the parse.

=head2 xqt

 @argv = xqt( $aaxp, $opt, @argv );

This subroutine loads C<@argv> into a localized C<@ARGV>, and then calls

 $plugin_class_name->__process( $aaxp, $opt );

on the plugin. It returns whatever was left in C<@ARGV> after the call.

The plugin class name is obtained from manifest constant C<CLASS>,

The first argument is the desired instance of
L<App::AckX::Preflight|App::AckX::Preflight> to pass to the plugin. If
this is omitted a default object is created.

The second argument (or first if C<$aaxp> is omitted) is the options
hash returned from L<prs()|/prs>. If this is omitted, an empty hash is
used.

Any remaining arguments are loaded into a localized C<@ARGV> before the
plugin is called.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
