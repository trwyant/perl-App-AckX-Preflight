package App::AckX::Preflight::Plugin;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{ :croak @CARP_NOT };

our $VERSION = '0.000_043';

use constant IN_SERVICE	=> 1;

sub __normalize_options {
    return;
}

{
    my %name;
    sub __name {
	my ( $class ) = @_;
	unless ( exists $name{$class} ) {
	    ( $name{$class} = lc $class ) =~ s/ .* :: //smx;
	}
	return $name{$class};
    }
}

sub __options {
    return;
}

sub __peek_opt {
    return;
}

sub __process {
    __die_hard( '__process() must be overridden' );
}

sub __wants_to_run {
    __die_hard( '__wants_to_run() must be overridden' );
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Plugin - Convenience superclass for plugins

=head1 SYNOPSIS

 package App::AckX::Preflight::Plugin::MyPlugin;
 
 # Subclassing this way is needed for the single-file version.
 
 require App::AckX::Preflight::Plugin;
 
 our @ISA;
 
 BEGIN {
     @ISA = qw{ App::AckX::Preflight::Plugin };
 }
 
 # May override this if you want options processing done for you. The
 # superclass' method returns nothing.
 sub __options {
     return qw{ myoption! };
 }

 # May override this if you want options processing done for you. The
 # superclass' method returns nothing. The difference from __options is
 # that these are not removed from @ARGV
 sub __peek_opt {
     return qw{ someone-elses-option! };
 }
 
 # Must override this. The superclass' method dies.
 sub __process {
     my ( undef, $aaxp, $opt ) = @_;
     ...
 }

=head1 DESCRIPTION

This abstract class is a convenience superclass for
L<App::AckX::Preflight|App::AckX::Preflight> plug-ins. Plug-ins B<may>
subclass this, but B<need not> do so as long as they conform to the
interface.

=head1 METHODS

This class supports the following package-private methods:

=head2 IN_SERVICE

This Boolean method can be a manifest constant. It is true indicating
that a plug-in is to be actually used. What this really is is a way to
rename or supersede plug-ins without actually removing them from the
system, since not all CPAN clients remove stuff.

The inherited value is true. You would normally only override this when
a plug-in is no longer to be used.

=head2 __name

This static method returns the name of the plugin. Unless overridden,
this is just the class name, converted to lower case and with everything
up to and including the last C<::> stripped.

=head2 __normalize_options

 $plugin_class->__normalize_options( \%opt );

This static method normalizes the options in the given hash, massaging
them as needed by the plug-in. If the plug-in has no options, or if the
output of C<getoptionsfromarray()> is sufficient, there is no need to
override this method.

=head2 __options

 $plugin_class->__options();

This static method returns the desired L<Getopt::Long|Getopt::Long>
option specifications. No arguments are passed other than the invocant.
If your plug-in does not have any options, or if you want to process
them yourself, do not override this method.

B<However>, not overriding this method has consequences for when the
L<__process()|/__process> method of your plug-in is called.
L<App::AckX::Preflight|App::AckX::Preflight> examines the command line,
and plug-ins that specify options via this method are called in the
order their options appear. If options for a specific plug-in occur more
than once, the last-occurring option determines the plug-in's order. If
more than one plug-in specifies the same option, they are called
ASCIIbetically, and they had better have the same syntax. Plug-ins that
return nothing, or whose options do not appear, are called last, in
ASCIIbetical order.

=head2 __peek_opt

 $plugin_class->__peek_opt();

This static method is similar to L<__options()|/__options>. Its return
is L<Getopt::Long|Getopt::Long> option specifications, and any of these
actually found appear in the C<$opt> argument passed to
L<__process()|/__process>.

The difference is that options specified by this method are not removed
from C<@ARGV>. The idea is that you specify here options that belong to
someone else but you want to know about.

=head2 __process

 $plugin_class->__process( $aaxp, $opt )

This static method processes C<@ARGV>. The arguments are the calling
L<App::AckX::Preflight|App::AckX::Preflight> object and a reference to
the options hash generated by processing the options specified by
L<__options()|/__options> and L<__peek_opt|/__peek_opt>. If those methods
returned nothing, an empty hash will be passed in.

This method B<must> be overridden.

This method is expected to do its job by modifying C<@ARGV>. It returns
nothing.

=head2 __wants_to_run

 $plugin->__wants_to_run( $opt )
   and $plugin->__process( $aaxp, $opt )

If this static method returns a true value, the plugin's C<__process()>
method will be run. Other functionality may also depend on this.

The argument is a reference to a hash of the command-line options parsed
from the command line which are relevant to the invocant -- that is, the
ones returned by the invocant's L<__options()|/__options> and
L<__peek_opt()|/__peek_opt> methods.

This method B<must> be overridden.

This method is expected to do its job by consulting C<$opt> and
C<@ARGV>.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AckX-Preflight>,
L<https://github.com/trwyant/perl-App-AckX-Preflight/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
