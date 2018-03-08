package App::AckX::Preflight;

use 5.008008;

use strict;
use warnings;

use constant SEARCH_PATH	=> join '::', __PACKAGE__, 'Plugin';
use constant MAX_DEPTH		=> do {
    my @parts = split qr{ :: }smx, SEARCH_PATH;
    1 + @parts;
};

use App::Ack();
use Carp;
use File::Basename ();
use Getopt::Long 2.33;
use Module::Pluggable::Object 5.2;

our $VERSION = '0.000_01';

sub die : method {	## no critic (ProhibitBuiltinHomonyms,RequireFinalReturn)
    my ( undef, @arg ) = @_;
    App::Ack::die( @arg );
}

{
    my $psr = Getopt::Long::Parser->new();
    $psr->configure( qw{
	no_auto_version no_ignore_case no_auto_abbrev pass_through
	},
    );

    sub getopt {
	my ( $self, @opt_spec ) = @_;
	my %opt;
	$psr->getoptions( \%opt, @opt_spec )
	    or $self->die( 'Invalid option' );	# TODO something better
	return \%opt;
    }
}

sub run {
    my ( $self ) = @_;
    $self->getopt(
	version	=> sub {
	    print <<"EOD";
@{[ __PACKAGE__ ]} $VERSION
App::Ack $App::Ack::VERSION
Perl $^V
EOD
	exit;
	},
    );

####

    # Go through all the plugins and index them by the options they
    # support.
    my %opt_to_plugin;
    my @plugin_without_opt;
    foreach my $plugin ( $self->__plugins() ) {
	my $p_rec = {
	    package	=> $plugin,
	};
	my $recorded;
	if ( $plugin->can( '__options' ) and my @opt_spec =
	    $plugin->__options() ) {
	    $p_rec->{options} = \@opt_spec;
	    foreach ( @opt_spec ) {
		my $os = $_;			# Don't want alias
		$os =~ s/ \A -+ //smx;		# Optional leading dash
		$os =~ s/ [:=+!] .* //smx;	# Argument spec.
		foreach my $o ( split qr{ [|] }smx, $os ) {
		    push @{ $opt_to_plugin{$o} ||= [] }, $p_rec;
		    $recorded++;
		}
	    }
	}
	$recorded
	    or push @plugin_without_opt, $p_rec;
    }

    # Go through all the arguments, find the options, and record, in
    # order, the plug-in, if any, that handles each. Only the first use
    # of a plug-in is recorded.
    my @found_p_rec;
    foreach my $arg ( @ARGV ) {
	$arg =~ m/ \A -+ ( [^=:]+ ) /smx
	    or next;
	foreach my $p_rec ( @{ $opt_to_plugin{$1} || [] } ) {
	    $p_rec->{found}++
		and next;
	    push @found_p_rec, $p_rec;
	}
    }

    # Finally, process all the plug-ins in order. The order is those
    # with options appearing on the command line in the order found,
    # followed by those without options on the command line in
    # alphabetical order.
    foreach my $p_rec ( @found_p_rec,
       	sort { $a->{package} cmp $b->{package} }
	    @plugin_without_opt,
	    map { @{ $_ } } values %opt_to_plugin ) {
	$p_rec->{processed}++
	    and next;
	my $code = $p_rec->{package}->can( '__process' )
	    or $p_rec->{package}->__process();	# Just to get the error.
	my $opt = $p_rec->{options} ?
	    $self->getopt( @{ $p_rec->{options} } ) :
	    {};
	$code->( $self, $opt );
    }

=begin comment

    foreach my $module ( $self->__plugins() ) {
	if ( my $code = $module->can( '__process' ) ) {
	    $code->( $self );
	} else {
	    $module->__process();	# Just to get the error.
	}
    }

=end comment

=cut

    return $self->__execute( ack => @ARGV );
}

sub __execute {
    my ( $self, @arg ) = @_;

    exec { $arg[0] } @arg
	or $self->die( "Failed to exec $arg[0]: $!" );
}

{
    my $mpo = Module::Pluggable::Object->new(
	filename	=> __FILE__,
	inner		=> 0,
	max_depth	=> MAX_DEPTH,
	package		=> __PACKAGE__,
	require		=> 1,
	search_path	=> SEARCH_PATH,
    );

    sub __plugins {
	return $mpo->plugins();
    }
}

1;

__END__

=head1 NAME

App::AckX::Preflight - Extend App::Ack

=head1 SYNOPSIS

 use App::AckX::Preflight;

 App::AckX::Preflight->run();

=head1 DESCRIPTION

This Perl module extends L<App::Ack|App::Ack>, in a way. All it really
does is to let you mung the arguments passed to the F<ack> script.

All the interesting functionality is provided by a plugin system.

=head1 METHODS

This class supports the following public methods:

=head2 die

 App::Ack::Preflight->die( 'Goodbye, cruel world!' );

This static method dies with the given message. If more than one
argument is specified they are concatenated. The message is prefixed by
the basename of C<$0>.

=head2 getopt

 my $opt = App::AckX::Preflight->getopt(
     qw{ foo! bar=s } );

This static method simply calls C<Getopt::Long::GetOptions>, with the
package configured appropriately for our use. Any arguments actually
processed will be removed from C<@ARGV>. The return is a reference to
the options hash.

The actual configuration used is

 no_auto_version no_ignore_case no_auto_abbrev pass_through

which is what L<App::Ack|App::Ack> uses.

=head2 run

 App::Ack::Preflight->run();

This static method calls the plugins, and then C<exec()>s F<ack>,
passing it C<@ARGV> as it stands after all the plugins have finished
with it.

Plug-ins that have an L<__options()|/__options> method are called in the
order the specified options appear on the command line. If a plug-in's
L<__options()|/__options> method returns more than one option, the first
one seen determines the order. If more than one plug-in specifies the
same option, they are processed in ASCIIbetical order.

Plug-ins whose options do not appear in the actual command, or that do
not implement an L<__options()|/__options> method are called last, in
ASCIIbetical order.

This method B<does not return.>

=head1 PLUGINS

Plugins B<must> be named
C<App::AckX::Preflight::Plugin::something_or_other>. They B<must not> be
subclassed from C<App::AckX::Preflight::Plugin>, because that does not
exist.

Plugins B<may> implement the following static methods:

=head2 __options

This static method returns L<Getopt::Long|Getopt::Long> option
specifiers for options associated with this plug-in. This method is
optional, but if it exists, and actually returns at least one option
specifier, two things happen:

=over

=item * The L<run()|/run> method will call L<getopt()|/getopt> on your
behalf, passing you the results.

=item * If any of the specified options actually appears in the command
line, this plug-in will be called before plug-ins that do not implement
L<__options()|/__options>, and before those whose options do not appear.

=back

Plug-ins that do not implement this are free to do options processing
when they are called, but their processing order is as through they had
no options.

Boiler plate for this method looks something like

 sub __options {
     return( qw{ foo=s bar|baz! } );
 }

=head2 __process

This static method is called as though it was invoked by this class,
even though it is not a member of this class. It returns nothing.  It is
allowed, and in fact expected, to modify C<@ARGV> in the course of its
duties.

This method B<must> be implemented. Boiler plate for this method would
look something like

 sub __process {
     my ( $preflight, $opt ) = @_;
     ...
 }

if the plug-in implements L<__options()|/__options>, or

 sub __process {
     my ( $preflight ) = @_;
     my $opt = $preflight->getopt( ... );
     ...
 }

if it does not. If the plug-in has no options, use the latter form but
omit the call to C<getopt()>.

=head1 SEE ALSO

L<App::Ack|App::Ack>.

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
