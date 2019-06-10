package App::AckX::Preflight::Syntax;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Util ();
use Exporter;
use List::Util 1.45 ();	# for uniqstr
use Text::Abbrev ();

our @EXPORT_OK;
our $VERSION;

my $ARG_SEP_RE;

my %VALID_EXPORT;


BEGIN {

    App::AckX::Preflight::Util->import(
	qw{
	    :croak
	    :syntax
	    __syntax_types
	    ACK_FILE_CLASS
	    IS_SINGLE_FILE
	    @CARP_NOT
	}
    );

    $ARG_SEP_RE = qr{ \s* [:;,] \s* }smx;

    # This is PRIVATE to the App-AckX-Preflight package.
    @EXPORT_OK = qw{ __normalize_options };

    %VALID_EXPORT = map { $_ => 1 } @EXPORT_OK;

    $VERSION = '0.000_023';
}

use constant IN_SERVICE		=> 1;
use constant IS_EXHAUSTIVE	=> 1;

use constant PLUGIN_MATCH	=> qr< \A @{[ __PACKAGE__ ]} :: [A-Z] >smxi;

my %WANT_SYNTAX;
my %SYNTAX_OPT;

sub __get_syntax_opt {
    my ( $class, $arg, $opt ) = @_;
    my $strict = ! $opt;
    $opt ||= {};
    my $mod_syntax = sub {
	my ( $name, $val ) = @_;
	push @{ $opt->{'syntax-mod'} ||= [] }, "-$name=$val";
	return;
    };
    App::AckX::Preflight::Util::__getopt( $arg, $opt,
	'syntax-add=s'	=> $mod_syntax,
	'syntax-del=s'	=> $mod_syntax,
	'syntax-set=s'	=> $mod_syntax,
	qw{ syntax=s@ syntax-type! },
    );
    if ( $strict && @{ $arg } ) {
	local $" = ', ';
	__die( "Unsupported arguments @{ $arg }" );
    }
    $class->__normalize_options( $opt );
    %SYNTAX_OPT  = map { $_ => $opt->{$_} } qw{ syntax-type };
    %WANT_SYNTAX = map { $_ => 1 } @{ $opt->{syntax} || [] };
    foreach ( @{ $opt->{'syntax-mod'} || [] } ) {
	my ( $filter, $mod, @val ) = @{ $_ };
	$filter->__handles_type_mod( $mod, @val );
    }

    wantarray
	or return $opt;

    my @arg;
    $opt->{syntax}
	and @{ $opt->{syntax} }
	and push @arg, '-syntax=' . join( ':', @{ $opt->{syntax} } );
    $opt->{'syntax-type'}
	and push @arg, '-syntax-type';
    foreach ( @{ $opt->{'syntax-mod'} || [] } ) {
	my ( undef, $mod, @val ) = @{ $_ };
	local $" = ':';
	push @arg, "-syntax-$mod=@val";
    }

    return @arg;
}

sub import {	## no critic (RequireArgUnpacking)
    my ( $class, @arg ) = @_;
    my @import;
    @arg = grep { $VALID_EXPORT{$_} ? do { push @import, $_; 0 } : 1 } @arg;
    __hot_patch();
    $class->__get_syntax_opt( \@arg );
    if ( @import ) {
	# The following line is what the (RequireArgUnpacking)
	# annotation actually refers to. But we have to dispatch
	# &Exporter::import via goto so that the symbols are exported to
	# our caller not to us, and we have to load the arguments into
	# @_ so that &Exporter::import will see them.
	@_ = ( $class, @import );
	goto &Exporter::import;
    }
    return;
}

sub __handles_resource {
    my ( $self, $rsrc ) = @_;
    foreach my $type ( $self->__handles_type() ) {
	foreach my $f ( @{ $App::Ack::mappings{$type} || [] } ) {
	    $f->filter( $rsrc )
		and return $type;
	}
    }
    return;
}

sub __handles_syntax {
    __die_hard( '__handles_syntax() must be overridden' );
}

{
    my %handles_type;

    sub __handles_type {
	my ( $self ) = @_;
	my $class = ref $self || $self;
	return( @{ $handles_type{$class} ||= [] } );
    }

    sub __handles_type_mod {
	my ( $self, $mod, @arg ) = @_;
	my $class = ref $self || $self;
	my $code = $class->can( "_handles_type_$mod" )
	    or __die_hard( "Invalid modification type '$mod'" );
	$code->( $class, @arg );
	return $self;
    }

    sub _handles_type_add {
	my ( $class, @arg ) = @_;
	$handles_type{$class} = [ List::Util::uniqstr( 
		@{ $handles_type{$class} || [] }, @arg ) ];
	return;
    }

    sub _handles_type_del {
	my ( $class, @arg ) = @_;
	my %del = map { $_ => 1 } @arg;
	$handles_type{$class} = [ grep { ! $del{$_} }
	    @{ $handles_type{$class} || [] } ];
	return;
    }

    sub _handles_type_set {
	my ( $class, @arg ) = @_;
	$handles_type{$class} = [ List::Util::uniqstr( @arg ) ];
	return;
    }

}

sub __my_attr {
    my ( $self ) = @_;
    return $self->{ scalar caller } ||= {};
}

sub FILL {
    my ( $self, $fh ) = @_;

    local $_ = undef;	# Should not be needed, but seems to be.

    my $attr = $self->__my_attr();

    while ( <$fh> ) {
	my $type = $self->__classify();
	$attr->{want}{$type}
	    or next;
	$attr->{syntax_type}
	    and $_ = join ':', substr( $type, 0, 4 ), $_;
	return $_;
    }
    return;
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;
    my $syntax_opt = $class->__syntax_opt();
    my $self = bless {}, ref $class || $class;
    my $attr = $self->__my_attr();
    $attr->{syntax_type} = $syntax_opt->{'syntax-type'};
    $attr->{want} = $self->__want_syntax();
    $self->__init();
    return $self;
}

sub SEEK {
    my ( undef, $posn, $whence, $fh ) = @_;
    return seek $fh, $posn, $whence;
}

sub TELL {
    my ( undef, $fh ) = @_;
    return tell $fh;
}

{
    my $syntax_abbrev;

    sub __normalize_options {
	my ( $invocant, $opt ) = @_;

	$syntax_abbrev ||= Text::Abbrev::abbrev( __syntax_types() );

	my $class = ref $invocant || $invocant;

	if ( $opt->{syntax} ) {
	    @{ $opt->{syntax} } = sort { $a cmp $b } List::Util::uniqstr(
		map { $syntax_abbrev->{$_} || 
		    __die( "Unsupported syntax type '$_'" ) }
		map { split $ARG_SEP_RE }
		@{ $opt->{syntax} } );
	}

	foreach ( @{ $opt->{'syntax-mod'} || [] } ) {
	    my ( $filter, $mod, @val ) =
		$invocant->_normalize_syntax_mod( $_ );
	    unless ( $class eq $filter ) {
		unshift @val, $filter;
		$val[0] =~ s/ \A @{[ __PACKAGE__ ]} :: //smxo;
	    }
	    $_ = [ $filter, $mod, @val ];
	}

	return;
    }
}

{

    my $plugins;

    sub _normalize_syntax_mod {
	my ( $invocant, $spec ) = @_;

	$plugins ||= { map { $_ => 1 } $invocant->__plugins() };

	my ( $name, $val ) = split qr{ = }smx, $spec, 2;
	$name =~ s/ \A - //smx;
	( my $mod = $name ) =~ s/ .* - //smx;
	my $filter = ref $invocant || $invocant;
	if ( __PACKAGE__ eq $filter ) {
	    $val =~ s/ \A ( \w+ (?: :: \w+ )* ) $ARG_SEP_RE? //smx
		or __die( "Invalid syntax filter name in -$name=$val" );
	    my $filter = $1;
	    $filter =~ m/ :: /smx
		or $filter = join '::', __PACKAGE__, $filter;
	}
	$plugins->{$filter}
	    or __die( "Unknown syntax filter $filter" );
	return ( $filter, $mod, split $ARG_SEP_RE, $val );
    }
}

{
    my %loaded;

    sub __plugins {
	my @rslt;
	foreach my $plugin ( @CARP_NOT ) {
	    $plugin =~ PLUGIN_MATCH
		or next;
	    IS_SINGLE_FILE
		or ( $loaded{$plugin} ||= eval "require $plugin; 1" )
		or next;
	    $plugin->IN_SERVICE()
		or next;
	    push @rslt, $plugin;
	}
	return @rslt;
    }
}

sub __syntax_opt {
    return \%SYNTAX_OPT;
}

sub __want_everything {
    my ( $class ) = @_;
    $class->IS_EXHAUSTIVE
	or return;
    my $want_syntax = $class->__want_syntax();
    foreach my $type ( $class->__handles_syntax() ) {
	$want_syntax->{$type}
	    or return;
    }
    return 1;
}

sub __want_syntax {
    my ( $class ) = @_;
    keys %WANT_SYNTAX
	and return \%WANT_SYNTAX;
    $SYNTAX_OPT{'syntax-type'}
	and return { map { $_ => 1 } $class->__handles_syntax() };
    return {};
}

use constant SYNTAX_FILTER_LAYER =>
    qr{ \A via\(App::AckX::Preflight::Syntax \b }smx;

# Hot patch the open() method on the App::Ack class that represents a
# file, so that we can inject ourselves as a PerlIO::via layer.
{
    my $open;
    sub __hot_patch {
	$open
	    and return;

	unless ( IS_SINGLE_FILE ) {
	    local $@ = undef;
	    eval sprintf 'require %s; 1', ACK_FILE_CLASS ## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
		or __die_hard( sprintf 'Can not load %s', ACK_FILE_CLASS );
	}

	$open = ACK_FILE_CLASS->can( 'open' )
	    or __die_hard( sprintf '%s does not implement open()', ACK_FILE_CLASS );

	no warnings qw{ redefine };	## no critic (ProhibitNoWarnings)
	no strict qw{ refs };

	my $repl = join '::', ACK_FILE_CLASS, 'open';

	*$repl = sub {
	    my ( $self ) = @_;

	    # If the caller is a resource or a filter we're not opening for
	    # the main scan. Just use the normal machinery.
	    my $caller = caller;
	    foreach my $c ( ACK_FILE_CLASS, qw{ App::Ack::Filter } ) {
		$caller->isa( $c )
		    and return $open->( $self );
	    }

	    # Foreach of the syntax filter plug-ins
	    foreach my $syntax ( App::AckX::Preflight::Syntax->__plugins() ) {

		# See if this resource is of the type serviced by this
		# module. If not, try the next.
		$syntax->__handles_resource( $self )
		    or next;

		# Open the file.
		my $fh = $open->( $self );

		# If we want everything and we're not reporting syntax types
		# we don't need the filter.
		$syntax->__want_everything()
		    and not $syntax->__syntax_opt()->{'syntax-type'}
		    and return $fh;

		# Check to see if we're already on the PerlIO stack. If so,
		# just return the file handle. The original open() is
		# idempotent, and ack makes use of this, so we have to
		# be idempotent also.
		foreach my $layer ( PerlIO::get_layers( $fh ) ) {
		    $layer =~ SYNTAX_FILTER_LAYER
			and return $fh;
		}

		# Insert the correct syntax filter into the PerlIO stack.
		binmode $fh, ":via($syntax)";

		# Return the handle
		return $fh;
	    }

	    # No syntax filter found. Just open the file and return the
	    # handle.
	    return $open->( $self );
	};

	return;
    }
}

1;

__END__

=head1 NAME

App::AckX::Preflight::Syntax - Superclass for App::AckX::Preflight syntax filters.

=head1 SYNOPSIS

Not directly invoked by the user.

=head1 DESCRIPTION

This Perl package is the superclass for an
L<App::AckX::Preflight|App::AckX::Preflight> syntax filter. These are
L<PerlIO::via|PerlIO::via>-style input filters that return only lines of
code that are of the requested syntax types.

Syntax filters are required to be named
C<App::AckX::Preflight::Syntax::something-or-other>, where the
C<something-or-other> may not begin with an underscore. Because this is
Perl, they need not subclass this class, but if not they B<must> conform
to its interface.

=head1 METHODS

In addition to the methods needed to implement a
L<PerlIO::via|PerlIO::via> PerlIO layer, the following methods are
provided:

=head2 __get_syntax_opt

This method is passed a reference to the argument list, and returns a
reference to an options hash. Anything parsed as an option will be
removed from the argument list.

The idea here is to provide common functionality. Specifically:

The options parsed are:

=over

=item -syntax

This option specifies the syntax types being requested. You can specify
more than one punctuated by commas, colons, or semicolons (i.e. anything
that matches C</[:;,]/>), and you can specify this option more than
once.  Multiple types in a single value will be parsed out, so that the
same options hash will be returned whether the input was

 -syntax=code,doc

or

 -syntax=code -syntax=doc

An exception will be raised if any arguments remain unconsumed, or if
any of the values for -syntax does not appear in the list returned by
C<__handles_syntax()>

=item -syntax-add

 -syntax-add=Perl:perlpod

This option adds one or more file types to the filter. It can be
specified more than once.

If the invocant is C<App::AckX::Preflight::Syntax>, the argument is a
syntax filter name and one or more C<ack> file types, punctuated by
commas, colons, or semicolons (i.e. anything that matches C</[:;,]/>).

If the invocant is a subclass of C<App::AckX::Preflight::Syntax>, the
filter is the invocant, and the argument is one or more C<ack> file
types, punctuated by commas, colons, or semicolons (i.e. anything that
matches C</[:;,]/>).

The filter name, if present, B<must> be the name of a syntax filter, but
the leading C<App::AckX::Preflight::Filter::> can be omitted. The file
types will be ineffective unless they are known to C<ack>.

=item -syntax-del

 -syntax-del=Perl:perlpod

This option removes one or more file types from the filter. It can be
specified more than once.

All the verbiage about the argument of C<-syntax-add>, above, applies
here also.

=item -syntax-set

 -syntax-set=Perl:perl:perlpod

This option associates one or more file types to the filter, replacing
any previously-handled file types. It can be specified more than once.

All the verbiage about the argument of C<-syntax-add>, above, applies
here also.

=item -syntax-type

If asserted, this Boolean option requests that the syntax filters prefix
each line returned with the syntax type computed for that line.

=back

=head2 import

This static method does not actually export or import anything; instead
it parses the import list to configure the syntax filters.

The import list is parsed by L<__get_syntax_opt()|/__get_syntax_opt>.
The import list must be completely consumed by this operation, or an
exception is raised. All C<--syntax> arguments must be valid or an
exception is raised.

=head2 __handles_resource

This static convenience method takes as its argument an
L<App::Ack::File|App::Ack::File> or L<App::Ack::Filter|App::Ack::Filter>
object and returns a true value if this syntax filter handles the file.
Otherwise it returns a false value.

=head2 __handles_syntax

This static method returns a list of the syntax types recognized by the
filter. These can be anything, but for sanity's sake the following list
(or such members of it that apply) is recommended:

=over

=item code

This should be self-explanatory.

=item comment

This is comments, both single-line and block comments that occupy whole
lines. Inline documentation should be C<'documentation'> if that can be
managed.

=item data

This should represent data embedded in the program. In the case of Perl,
it is intended for the non-POD stuff after C<__DATA__> or C<__END__>. It
is not intended that this include here documents.

=item documentation

This represents inline documentation. In the case of Perl it should
include POD. In the case of Java it should include Javadoc for sure, and
maybe all inline comments.

=item metadata

This represents data about the program. It should include the shebang
line for such formats as support it.

=item other

This is a catch-all category. It should be used sparingly if at all.

=back

=head2 __handles_type

This static method returns a list of the file types recognized by the
filter.

These need to conform to F<ack>'s file types, otherwise the
filter is useless.

This will return an empty list unless
L<__handles_type_mod()|/__handles_type_mod> has been called on the
invocant to set or add types. It is recommended that subclasses
initialize themselves by calling

 __PACKAGE__->__handles_type_mod( set => ... );

=head2 __handles_type_mod

 $syntax_filter->__handles_type_mod( qw{ add mytype } );

This static method modifies the list of the file types recognized by the
filter. These need to conform to F<ack>'s file types, otherwise the
filter is useless.

The arguments are the modification to make (C<'add'>, C<'del'>, or
C<'set'>), and the list of F<ack> file types involved.

Subclasses B<should> call

 __PACKAGE__->__handles_type_mod( set => ... )

to initialize themselves. Subclasses that do not do this will not be
applied to any file types by default. They will still be applied if the
user passes the appropriate options.

=head2 PUSHED

This static method is part of the L<PerlIO::via|PerlIO::via> interface.
It is called when this class is pushed onto the stack.  It manufactures,
initializes, and returns a new object.

=head2 __init

This method B<must> be overridden by the subclass. It is called by
L<PUSHED()|/PUSHED> once the object has been created.

If this method needs to set up any attributes, it B<must> do so by
calling L<__my_attr()|/__my_attr> on its invocant, and storing them in
the resultant hash reference, rather than directly in the invocant.

=head2 FILL

This method is part of the L<PerlIO::via|PerlIO::via> interface. It is
called when a C<readline>/C<< <> >> operator is executed on the file
handle. It reads the next-lower-level layer until a line is found that
is one of the syntax types that is being returned, and returns that line
to the next-higher layer. At end of file, nothing is returned.

=head2 __classify

This method B<must> be overridden by the subclass. It is called by
L<FILL()|/FILL> once a line of input has been read. The input will be in
the topic variable (a.k.a. C<$_>).

This method returns the syntax type of the line based on the contents of
C<$_>, and possibly of the contents of the hash returned by the
L<__my_attr()|/__my_attr> method, which this method is free to modify.

=head2 SEEK

This method is part of the L<PerlIO::via|PerlIO::via> interface. It is
called when a C<seek()> operation is executed on the file handle. All
this does is seek the next-lower-level layer. This method is needed
because the default behavior is to fail.

=head2 TELL

This method is part of the L<PerlIO::via|PerlIO::via> interface. It is
called when a C<tell()> operation is executed on the file handle. All
this does is call C<tell()> on the next-lower-level layer. This method
is needed because the default behavior is undefined. I am not sure that
Ack actually uses this, but my futzing around suggested that failure was
a real possibility.

=head2 __my_attr

This method returns a hash that the caller can use to store the data it
needs to do its job, creating it if necessary. This is intended for the
use of the L<__init()|/__init> and L<__classify()|/__classify> methods.

=head2 IN_SERVICE

This Boolean method can be a manifest constant. It is true indicating
that a plug-in is to be actually used. What this really is is a way to
rename or supersede plug-ins without actually removing them from the
system, since not all CPAN clients remove stuff.

The inherited value is true. You would normally only override this when
a plug-in is no longer to be used.

=head2 IS_EXHAUSTIVE

This Boolean method can (and probably should) be a manifest constant. If
it returns a true value, the syntax-filtering system will assume that
the syntax types returned by the L<__handles_syntax()|/__handles_syntax>
method describe all lines in the file, and optimize based on that
assumption.

The inherited value is true. The only reason I can think of to override
this is if there are lines of a file that would be returned (or would
not be returned) no matter what combination of syntax types was
requested.

B<If> this is true B<and> no syntax types are requested, the filter
should simply return C<undef> when executed.

=head2 __want_everything

 $syntax_filter->__want_everything()
   and return;

This static method determines whether, given the syntax types actually
requested, a given syntax filter would pass all lines in any conceivable
file. It returns a true value if and only if all of the following
conditions are true:

=over

=item L<IS_EXHAUSTIVE|/IS_EXHAUSTIVE> is true;

=item all syntax type returned by L<__handles_syntax|/__handles_syntax>
appear in the hash returned by L<__want_syntax()|/__want_syntax>.

=back

=head2 __plugins

This static method returns the full class names of all in-service
syntax filters.

=head2 __syntax_opt

This static method returns a reference to a hash containing the values
of options that the individual filters need to see. At the moment this
is:

=over

=item syntax-type

See C<-syntax-type> above.

=back

=head2 __want_everything

This convenience static method returns a true value if and only if the
filter is exhaustive and every supported syntax type was requested.

=head2 __want_syntax

This static method returns a reference to a hash whose keys are the
syntax types parsed from the import list and whose values are true.

=head1 SEE ALSO

L<App::AckX::Preflight|App::AckX::Preflight>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
