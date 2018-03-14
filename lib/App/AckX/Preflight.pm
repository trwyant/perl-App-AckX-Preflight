package App::AckX::Preflight;

use 5.008008;

use strict;
use warnings;

use App::Ack ();
use App::AckX::Preflight::Util qw{ :all };
use Carp ();
use Cwd ();
use File::Basename ();
use File::Spec;
use Module::Pluggable::Object 5.2;
use Pod::Usage ();
use Text::ParseWords ();

our $VERSION = '0.000_001';
our $COPYRIGHT = 'Copyright (C) 2018 by Thomas R. Wyant, III';

use constant IS_VMS	=> 'VMS' eq $^O;
use constant IS_WINDOWS	=> { map { $_ => 1 } qw{ dos MSWin32 } }->{$^O};

BEGIN {
    IS_WINDOWS
	and require Win32;
}

use constant FILE_ID_IS_INODE	=> ! { map { $_ => 1 }
    qw{ dos MSWin32 VMS } }->{$^O};

use constant SEARCH_PATH	=> join '::', __PACKAGE__, 'Plugin';
use constant MAX_DEPTH		=> do {
    my @parts = split qr{ :: }smx, SEARCH_PATH;
    1 + @parts;
};

{
    my %default = (
	global	=> IS_VMS ? undef :	# TODO what, exactly?
	    IS_WINDOWS ? Win32::CSIDL_COMMON_APPDATA() :
	    '/etc',
	home	=> IS_VMS ? $ENV{'SYS$LOGIN'} :
	    IS_WINDOWS ? Win32::CSIDL_APPDATA() :
	    $ENV{HOME},
    );

    sub new {
	my ( $class, %arg ) = @_;

	ref $class
	    and %arg = ( %{ $class }, %arg );

	foreach ( keys %arg ) {
	    exists $default{$_}
		or Carp::croak "Argument '$_' not supported";
	}

	foreach ( keys %default ) {
	    defined $arg{$_}
		or $arg{$_} = $default{$_};
	}

	foreach ( qw{ global home } ) {
	    -d $arg{$_}
		or Carp::croak "Argument '$_' must be a directory";
	}

	return bless \%arg, ref $class || $class;
    }

    sub global {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{global};
    }

    sub home {
	my ( $self ) = @_;
	ref $self
	    or $self = \%default;
	return $self->{home};
    }
}

sub run {
    my ( $self ) = @_;
    __getopt(
	version	=> sub {
	    print <<"EOD";
@{[ __PACKAGE__ ]} $VERSION
    $COPYRIGHT
App::Ack $App::Ack::VERSION
    $App::Ack::COPYRIGHT
Perl $^V
EOD
	    exit;
	},
	'help|man' => sub {
	    @ARGV
		and defined $ARGV[0]
		and '' ne $ARGV[0]
		or Pod::Usage::pod2usage( { -verbose => 2 } );
	    if ( 'plugins' eq $ARGV[0] ) {
		foreach ( $self->__plugins() ) {
		    s/ .* :: //smx;
		    print STDERR "    $_\n";
		}
		exit 1;
	    }
	    my $match = qr{ :: \Q$ARGV[0]\E \z }smx;
	    foreach ( $self->__plugins() ) {
		$_ =~ $match
		    or next;
		( my $file = "$_.pm" ) =~ s| :: |/|smxg;
		Pod::Usage::pod2usage( { -verbose => 2, -input => $INC{$file} } );
	    }
	    __warn( "No such plug-in as '$ARGV[0]'" );
	    exit 1;
	},
    );

    $self->__process_config_files( $self->__find_config_files() );

    foreach my $p_rec ( $self->__marshal_plugins ) {
	my $plugin = $p_rec->{package};
	my $opt = __getopt_for_plugin( $plugin );
	$plugin->__process( $self, $opt );
    }

    return $self->__execute( ack => @ARGV );
}

sub __execute {
    my ( undef, @arg ) = @_;	# Invocant unused

    exec { $arg[0] } @arg
	or __die( "Failed to exec $arg[0]: $!" );
}

# We go through this to defined __filter_files because we are rummaging
# around in the internals of App::Ack, and who knows what may break?
{	# Localize $@

    local $@ = undef;

    eval {
	require App::Ack::ConfigLoader;
	App::Ack::ConfigLoader->can( 'retrieve_arg_sources' )
	    and App::Ack::ConfigLoader->can( 'process_args' )
	    or return;
	require App::Ack::Filter;
	# filter() not implemented on superclass
	require App::Ack::Filter::Collection;
	App::Ack::Filter::Collection->can( 'filter' )
	    or return;
	require App::Ack::Filter::Default;
	App::Ack::Filter::Default->can( 'filter' )
	    or return;
	require App::Ack::Filter::Extension;
	App::Ack::Filter::Extension->can( 'filter' )
	    or return;
	require App::Ack::Filter::FirstLineMatch;
	App::Ack::Filter::FirstLineMatch->can( 'filter' )
	    or return;
	require App::Ack::Filter::Inverse;
	# etc
	require App::Ack::Filter::Is;
	require App::Ack::Filter::IsPath;
	require App::Ack::Filter::Match;
	require App::Ack::Resource;
	App::Ack::Resource->can( 'new' )
	    or return;

	*__filter_files = sub {		# sub __filter_files
	    my ( $self, @files ) = @_;

	    unless ( $self->{filters} ) {

		local @ARGV = @ARGV;

		my @arg_sources = App::Ack::ConfigLoader::retrieve_arg_sources();

		my %known_type;
		my $argv;

		foreach my $as ( @arg_sources ) {
		    if ( 'ARGV' eq $as->{name} ) {
			$argv = $as;
		    } else {
			my @contents = @{ $as->{contents} };
			while ( @contents ) {
			    local $_ = shift @contents;
			    if ( m/ \A --? type- ( add | set | del )
				( = ( [^:]+) | \z ) /smx ) {
				my $verb = $1;
				my $type = $3;
				unless ( $type ) {
				    local $_ = shift @contents;
				    m/ \A ( [^:]+ ) /smx
					or next;
				    $type = $1;
				}
				if ( 'del' eq $verb ) {
				    delete $known_type{$type};
				} else {
				    $known_type{$type} = 1;
				}
			    }
			}
		    }
		}

		if ( $argv ) {
		    my @contents = @{ $argv->{contents} };
		    my @rslt;
		    while ( @contents ) {
			local $_ = shift @contents;
			if ( m/ \A --? type ( = | \z ) /smx ) {
			    push @rslt, $_;
			    $1
				or push @rslt, shift @contents;
			} elsif ( m/ \A --? ( [[:alpha:]0-9]+ ) \z /smx &&
			    $known_type{$1} ) {
			    push @rslt, $_;
			}
		    }
		    @{ $argv->{contents} } = @rslt;
		}

		my $opt = App::Ack::ConfigLoader::process_args( @arg_sources );

		$self->{filters} = $opt->{filters};
	    }

	    my @rslt;
	    foreach my $file ( @files ) {
		my $r = App::Ack::Resource->new( $file );
		foreach my $filter ( @{ $self->{filters} } ) {
		    $filter->filter( $r )
			or next;
		    push @rslt, $file;
		    last;
		}
	    }

	    return @rslt;
	};

	*__filter_available = sub { 1 };	# sub __filter_available

	1;
    } or do {
	*__filter_files = sub {	# sub __filter_files
	    my ( undef, @files ) = @_;
	    return @files;
	};

	*__filter_available = sub { 0 };	# sub __filter_available
    };
}	# End localized $@

sub __find_config_files {
    my ( $self ) = @_;
    my $opt = __getopt( qw{ ackxprc=s ignore-ackxp-defaults! } );

    # I want to leave --env/--noenv in the command line for ack, but I
    # need to know its value. Fortunately ack does not allow option
    # abbreviation, so I can (I hope!) just traverse the command line
    # and recognize it in-place myself;
    my $use_env = 1;
    {
	local @ARGV = @ARGV;
	__getopt( 'env!' => \$use_env );
    }

    my @files;

    # Files are processed in most-significant to least-significant
    # order, as shown below. Starred sources are disabled by --noenv

    # ACKXP_OPTIONS environment variable (*)
    $use_env
	and defined $ENV{ACKXP_OPTIONS}
	and '' ne $ENV{ACKXP_OPTIONS}
	and push @files, \$ENV{ACKXP_OPTIONS};
    # --ackxprc
    defined $opt->{ackxprc}
	and push @files, $opt->{ackxprc};

    if ( $use_env ) {
	# Project ackprc (walk directories current to root inclusive)(*)
	my $cwd = Cwd::getcwd();
	# TODO ack untaints this, but ...
	my @parts = File::Spec->splitdir( $cwd );
	while ( @parts ) {
	    my $path = $self->_file_from_parts( catdir => @parts )
		or next;
	    push @files, $path;
	    last;
	} continue {
	    pop @parts;
	}
	# User's home ackxprc (ACKXPRC or system-dependant location)(*)
	push @files, $self->_file_from_env( catfile => 'ACKXPRC' ) ||
	    $self->_file_from_parts( catdir => $self->home() );
	# Global ackxprc(*)
	push @files, $self->_file_from_parts(
	    catdir => $self->global(), [ 'ackxprc' ] );
    }
    # Built-in defaults (unless --ignore-ackxp-defaults)

    my %seen;
    return ( grep { ! $seen{_file_id( $_ )}++ } @files );
}

sub _file_from_env {	## no critic (RequireArgUnpacking)
    my ( $self, $method, @arg ) = @_;
    @arg
	or return;
    foreach ( @arg ) {
	defined $ENV{$_}
	    and '' ne $ENV{$_}
	    or return;
	$_ = $ENV{$_};
    }
    @_ = ( $self, $method, @arg );
    goto &_file_from_parts;
}

sub _file_from_parts {
    my ( undef, $method, @arg ) = @_;	# Invocant unused
    my $names = ARRAY_REF eq ref $arg[-1] ? pop @arg : [ qw{ .ackxprc
	_ackxprc } ];
    @arg
	or Carp::confess(
	'Progeamming error - No file parts specified' );
    my $path = @arg > 1 ? File::Spec->$method( @arg ) : $arg[0];
    -d $path
	or return $path;
    my @f;
    foreach my $base ( @{ $names } ) {
	my $p = File::Spec->catfile( $path, $base );
	-r $p
	    and push @f, $p;
    }
    @f
	or return;
    local $" = ' and ';
    @f > 1
	and __die( "Both @f found; delete one" );
    return $f[0];
}

sub _file_id {
    my ( $path ) = @_;
    return FILE_ID_IS_INODE ?
	join( ':', ( stat $path )[ 0, 1 ] ) :
	Cwd::abs_path( $path );
}

# Its own code so we can test it.
sub __marshal_plugins {
    my ( $self ) = @_;

    # Go through all the plugins and index them by the options they
    # support.
    my %opt_to_plugin;
    my @plugin_without_opt;
    foreach my $plugin ( $self->__plugins() ) {
	my $p_rec = {
	    package	=> $plugin,
	};
	my $recorded;
	if ( my @opt_spec = $plugin->__options() ) {
	    $p_rec->{options} = \@opt_spec;
	    foreach ( @opt_spec ) {
		my $os = $_;			# Don't want alias
		$os =~ s/ \A -+ //smx;		# Optional leading dash
		$os =~ s/ ( [:=+!] ) .* //smx;	# Argument spec.
		my $negated = '!' eq $1;
		foreach my $o ( split qr{ [|] }smx, $os ) {
		    push @{ $opt_to_plugin{$o} ||= [] }, $p_rec;
		    if ( $negated ) {
			push @{ $opt_to_plugin{"no$o"} ||= [] }, $p_rec;
			push @{ $opt_to_plugin{"no-$o"} ||= [] }, $p_rec;
		    }
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
    my %num_found;
    foreach my $arg ( reverse @ARGV ) {
	$arg =~ m/ \A -+ ( [^=:]+ ) /smx
	    or next;
	foreach my $p_rec ( @{ $opt_to_plugin{$1} || [] } ) {
	    $num_found{$p_rec->{package}}++
		and next;
	    push @found_p_rec, $p_rec;
	}
    }

    %num_found = ();

    return (
	grep { ! $num_found{$_->{package}}++ }
	reverse( @found_p_rec ),
       	sort { $a->{package} cmp $b->{package} }
	    @plugin_without_opt,
	    map { @{ $_ } } values %opt_to_plugin,
    );
}

{

    my $mpo;

    sub __plugins {
	my ( $self ) = @_;
	$mpo ||= Module::Pluggable::Object->new(	# Oh, for state()
	    $self->__module_pluggable_object_new_args(),
	);
	return $mpo->plugins();
    }
}

sub __module_pluggable_object_new_args {
    return (
	filename	=> __FILE__,
	inner		=> 0,
	max_depth	=> MAX_DEPTH,
	package		=> __PACKAGE__,
	require		=> 1,
	search_path	=> SEARCH_PATH,
    );
}

sub __process_config_files {
    my ( undef, @files ) = @_;			# Invocant unused
    foreach my $fn ( @files ) {
	my @args;
	if ( SCALAR_REF eq ref $fn ) {
	    @args = Text::ParseWords::shellwords( ${ $fn } );
	} else {
	    my $fh = __open_for_read( $fn );	# Dies on error.
	    while ( <$fh> ) {
		m/ \S /smx
		    and not m/ \A \s* [#] /smx
		    or next;
		chomp;
		push @args, $_;
	    }
	    close $fh;
	}
	splice @ARGV, 0, 0, @args;
    }
    return;
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

=head2 new

 my $aaxp = App::AckX::Preflight->new();

This static method instantiates an C<App::AckX::Preflight> object. It
takes the following optional arguments as name/value pairs.

=over

=item global

This is the name of the directory in which the global configuration file
is stored. The directory must exist. The default is system-dependant,
and chosen to be compatible with L<App::Ack|App::Ack>:

=over

=item VMS: None. I will fix this if someone will tell me what it should
be.

=item Windows: C<Win32::CSIDL_COMMON_APPDATA()>.

=item anything else: C<'/etc'>.

=back

=item home

This is the name of the directory in which the user's configuration file
is stored. The directory must exist. The default is system-dependant,
and chosen to be compatible with L<App::Ack|App::Ack>:

=over

=item VMS: C<$ENV{'SYS$LOGIN'}>.

=item Windows: C<Win32::CSIDL_APPDATA()>.

=item anything else: C<$ENV{HOME}>.

=back

=back

If C<new()> is called as a normal method it clones its invocant,
applying the arguments (if any) after the clone.

=head2 global

 say App::Ack::Preflight->global();
 say $aaxp->global();

If called on an object, this method returns the value of the C<{global}>
attribute, whether explicit or defaulted. If called statically, it
returns the default value of the C<{global}> attribute.

=head2 home

 say App::Ack::Preflight->home();
 say $aaxp->home();

If called on an object, this method returns the value of the C<{home}>
attribute, whether explicit or defaulted. If called statically, it
returns the default value of the C<{home}> attribute.

=head2 __filter_available

 $self->__filter_available()
     and print "Filters are supported\n";

This method returns a true value if L<App::Ack|App::Ack> filters are
available, and a false value if not.

The use of L<App::Ack|App::Ack> filters requires a certain amount of
mucking around in the internals of L<App::Ack|App::Ack>. What a true
return really means is that all requisite modules loaded and supported
all requisite methods.

=head2 __filter_files

 my @rslt = $self->__filter_files( @files );

This method takes as its arguments zero or more file names. If
L<App::Ack|App::Ack> filters are supported (see
L<__filter_available()|/__filter_available>), the return is the names of
those files that passed the filters specified on the command line. If
filters are not supported, returns all file names.

=head2 run

 App::Ack::Preflight->run();
 $aaxp->run();

This method reads all the configuration files, calls the plugins,
and then C<exec()>s F<ack>, passing it C<@ARGV> as it stands after all
the plugins have finished with it.

Plug-ins that have an L<__options()|/__options> method are called in the
order the specified options appear on the command line. If a plug-in's
L<__options()|/__options> method returns more than one option, or if an
option is specified more than once, the last one seen determines the
order. If more than one plug-in specifies the same option, they are
processed in ASCIIbetical order.

Plug-ins whose options do not appear in the actual command, or that do
not implement an L<__options()|/__options> method are called last, in
ASCIIbetical order.

This method B<does not return.>

=head1 PLUGINS

Plugins B<must> be named
C<App::AckX::Preflight::Plugin::something_or_other>. They B<may> be
subclassed from C<App::AckX::Preflight::Plugin>, but need not as long as
they conform to its interface.

=head1 CONFIGURATION

The configuration system mirrors that of L<App::Ack|App::Ack> itself, as
nearly as I can manage. The only known difference is support for VMS.
Any other differences will be resolved in favor of C<App::Ack|App::Ack>.

Like L<App::Ack|App::Ack>'s configuration system,
C<App::AckX::Preflight>'s configuration is simply a list of default
command line options to be prepended to the command line. Options
specific to C<App::AckX::Preflight> will be removed before the command
line is presented to F<ack>.

The Configuration comes from the following sources, in order from
most-general to most-specific. If an option is specified more than once,
the most-specific one rules. It is probably a 'feature' (in the sense of
'documented bug') that C<App::AckX::Preflight> configuration data trumps
L<App::Ack|App::Ack> configuration data.

=over

=item Global configuration file.

This optional file is named F<ackxprc>, and lives in the directory
reported by the L<global()|/global> method.

This configuration file is ignored if C<--noenv> is specified.

=item User-specific configuration file.

If environment variable C<ACKXPRC> exists and is non-empty, it points to
the user-specific configuration file, which must exist.

Otherwise this optional file is whichever of F<.ackxprc> or F<_ackxprc>
actually exists. It is an error if both exist.

This configuration file is ignored if C<--noenv> is specified.

=item Project-specific configuration file.

This optional file is the first of F<.ackxprc> or F<_ackxprc> found by
walking up the directory tree from the current directory. It is an error
if both files are found in the same directory.

This configuration file is ignored if C<--noenv> is specified.

=item Configuration file specified by C<--ackxprc>

If this option is specified, the file must exist.

=item The contents of environment variable C<ACKXP_OPTIONS>

This optional environment variable will be parsed by
C<Text::Parsewords::shellwords()>.

This environment variable is ignored if C<--noenv> is specified.

=back

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
