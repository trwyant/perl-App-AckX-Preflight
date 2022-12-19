package App::AckX::Preflight::Syntax;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Util
    qw{
	:croak
	:syntax
	__syntax_types
	ACK_FILE_CLASS
	@CARP_NOT
    };
use Exporter;
use Fcntl qw{ :seek };
use List::Util 1.45 ();	# for uniqstr
use Scope::Guard ();
use Text::Abbrev ();

# This is PRIVATE to the App-AckX-Preflight package.
our @EXPORT_OK = qw{ __normalize_options };

our $VERSION = '0.000_043';

my $ARG_SEP_RE = qr{ \s* [:;,] \s* }smx;

my %VALID_EXPORT = map { $_ => 1 } @EXPORT_OK;

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
	( my $alias = $name ) =~ tr/_/-/;
	push @{ $opt->{syntax_mod} ||= [] }, "--$alias=$val";
	return;
    };
    App::AckX::Preflight::Util::__getopt( $arg, $opt,
	'syntax_add|syntax-add=s'	=> $mod_syntax,
	'syntax_del|syntax-del=s'	=> $mod_syntax,
	'syntax_set|syntax-set=s'	=> $mod_syntax,
	qw{
	    syntax=s@
	    syntax-empty-code-is-comment!
	    syntax_type|syntax-type!
	    syntax_wc|syntax-wc!
	    syntax_wc_only|syntax-wc-only!
	},
    );
    if ( $strict && @{ $arg } ) {
	local $" = ', ';
	__die( "Unsupported arguments @{ $arg }" );
    }
    $opt->{syntax_wc} ||= $opt->{syntax_wc_only};
    $class->__normalize_options( $opt );
    %SYNTAX_OPT  = map { $_ => $opt->{$_} } qw{
	syntax-empty-code-is-comment
	syntax_type syntax_wc syntax_wc_only
	};
    %WANT_SYNTAX = map { $_ => 1 } @{ $opt->{syntax} || [] };
    foreach ( @{ $opt->{syntax_mod} || [] } ) {
	my ( $filter, $mod, @val ) = @{ $_ };
	$filter->__handles_type_mod( $mod, @val );
    }

    wantarray
	or return $opt;

    my @arg;
    $opt->{syntax}
	and @{ $opt->{syntax} }
	and push @arg, '--syntax=' . join( ':', @{ $opt->{syntax} } );
    foreach my $name ( qw{
	syntax-empty-code-is-comment
	syntax_type syntax_wc syntax_wc_only
    } ) {
	$opt->{$name}
	    or next;
	( my $alias = $name ) =~ tr/_/-/;
	push @arg, "--$alias";
    }
    foreach ( @{ $opt->{syntax_mod} || [] } ) {
	my ( undef, $mod, @val ) = @{ $_ };
	local $" = ':';
	push @arg, "--syntax-$mod=@val";
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

    my $attr = $self->__my_attr();

    # Localize so we do not hold handle after exiting FILL.
    local $attr->{input_handle} = $fh;

    local $_ = undef;	# while (<>) does not localize $_

    while ( <$fh> ) {
	my $type = do {
	    # Localize so that scope guard created by
	    # __get_peek_handle() (if called) will be cleaned up.
	    local $attr->{input_scope_guard} = undef;
	    $self->__classify();
	};
	SYNTAX_CODE eq $type
	    and $attr->{syntax_empty_code_is_comment}
	    and m/ \A \s* \z /smx
	    and $type = SYNTAX_COMMENT;
	$attr->{want}{$type}
	    or next;
	$attr->{syntax_type}
	    and $_ = join ':', substr( $type, 0, 4 ), $_;
	if ( $attr->{syntax_wc} ) {
	    my $info = $attr->{syntax_wc}{$type} ||= {};
	    $info->{char} += length;
	    # It would be more natural to just call split() in scalar
	    # context, but that walks on @_ in Perls before 5.11. It's
	    # use an intermediate array of localize @_.
	    # my @words = split qr< \s+ >smx;
	    # $info->{word} += @words;
	    $info->{word} += scalar( () = m/ ( \S+ ) /smxg );
	    $info->{line} += 1;
	    $attr->{syntax_wc_only}
		and next;
	}
	return $_;
    }
    if ( $attr->{syntax_wc} ) {
	if ( my @keys = sort keys %{ $attr->{syntax_wc} } ) {
	    my $type = shift @keys;
	    my $info = delete $attr->{syntax_wc}{$type};
	    my $t = substr $type, 0, 4;
	    $. += 1;	# Because ack uses this to generate line numbers
	    return "$t:\t$info->{line}\t$info->{word}\t$info->{char}\n";
	}
	delete $attr->{syntax_wc};
    }
    return;
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;
    my $syntax_opt = $class->__syntax_opt();
    my $self = bless {}, ref $class || $class;
    my $attr = $self->__my_attr();
    $attr->{syntax_empty_code_is_comment} =
	$syntax_opt->{'syntax-empty-code-is-comment'};
    $attr->{syntax_type} = $syntax_opt->{syntax_type};
    $attr->{want} = $self->__want_syntax();
    $syntax_opt->{syntax_wc}
	and $attr->{syntax_wc} = {};
    $attr->{syntax_wc_only} = $syntax_opt->{syntax_wc_only};
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

	$syntax_abbrev ||= Text::Abbrev::abbrev( __syntax_types(), 'none' );

	my $class = ref $invocant || $invocant;

	if ( $opt->{syntax} ) {
	    my @syntax;
	    foreach ( map { split $ARG_SEP_RE } @{ $opt->{syntax} } ) {
		defined $syntax_abbrev->{$_}
		    or __die( "Unsupported syntax type '$_'" );
		$_ = $syntax_abbrev->{$_};
		if ( $_ eq 'none' ) {
		    @syntax = ();
		} else {
		    push @syntax, $_;
		}
	    }
	    if ( @syntax ) {
		@{ $opt->{syntax} } = sort { $a cmp $b }
		    List::Util::uniqstr( @syntax );
	    } else {
		delete $opt->{syntax};
	    }
	}

	foreach ( @{ $opt->{syntax_mod} || [] } ) {
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
	$name =~ s/ \A --? //smx;
	( my $mod = $name ) =~ s/ .* [-_] //smx;
	my $filter = ref $invocant || $invocant;
	if ( __PACKAGE__ eq $filter ) {
	    $val =~ s/ \A ( \w+ (?: :: \w+ )* ) $ARG_SEP_RE? //smx
		or __die( "Invalid syntax filter name in --$name=$val" );
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
	    ( $loaded{$plugin} ||= eval "require $plugin; 1" )
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
    ( $SYNTAX_OPT{syntax_type} || $SYNTAX_OPT{syntax_wc} )
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

	{
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

		# If we want everything and we're not reporting syntax
		# types or word count we don't need the filter.
		if ( $syntax->__want_everything() ) {
		    my $opt = $syntax->__syntax_opt();
		    $opt->{syntax_type}
			or $opt->{syntax_wc}
			or return $fh;
		}

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

# FIXME this is a bit clunky. What I think I really want is return a
# handle that triggers the cleanup when it goes out of scope. That seems
# to require occupying multiple slots in a glob, but I have so far been
# unable to make that work.
sub __get_peek_handle {
    my ( $self ) = @_;

    my $attr = $self->__my_attr();
    my $fh = $attr->{input_handle}
	or __die_hard( 'No input handle defined' );

    unless ( $attr->{input_scope_guard} ) {
	my $position = tell $fh;
	my $line = $.;
	$attr->{input_scope_guard} = Scope::Guard->new( sub {
		seek $fh, $position, SEEK_SET;
		$. = $line;	## no critic (RequireLocalizedPunctuationVars)
		return;
	    }
	);
    }

    return $fh;
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

=item --syntax

This option specifies the syntax types being requested. You can specify
more than one punctuated by commas, colons, or semicolons (i.e. anything
that matches C</[:;,]/>), and you can specify this option more than
once.  Multiple types in a single value will be parsed out, so that the
same options hash will be returned whether the input was

 --syntax=code,doc

or

 --syntax=code --syntax=doc

The valid syntax types are hose returned by
L<__handles_syntax()|/__handles_syntax>, plus C<'none'>. Syntax types
can be abbreviated, as long as the abbreviation is unique.

Value C<'none'> cancels any C<--syntax> values specified up to the time
at which it is encountered.

=item --syntax-add

 --syntax-add=Perl:perlpod

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

=item --syntax-del

 --syntax-del=Perl:perlpod

This option removes one or more file types from the filter. It can be
specified more than once.

All the verbiage about the argument of C<--syntax-add>, above, applies
here also.

=item --syntax-set

 --syntax-set=Perl:perl:perlpod

This option associates one or more file types to the filter, replacing
any previously-handled file types. It can be specified more than once.

All the verbiage about the argument of C<--syntax-add>, above, applies
here also.

=item --syntax-type

If asserted, this Boolean option requests that the syntax filters prefix
each line returned with the syntax type computed for that line.

=item --syntax-wc

If asserted, this Boolean option requests that L<wc (1)>-style
information on each syntax type be appended to the output.

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
filter. The returned values must be selected from the following list.

=over

=item code

This is probably self-explanatory.

=item comment

This is comments, both single-line and block comments that occupy whole
lines. Inline documentation should be C<'documentation'> if that can be
managed. In file types with C-style comments, only full-line comments
will appear here.

=item data

This is data embedded in the program. In the case of Perl, it is
intended for the non-POD stuff after C<__DATA__> or C<__END__>. It is
not intended that this include here documents.

=item documentation

This is structured inline documentation. For Perl it would be POD. For
Java it would be Javadoc, which would B<not> also be considered a
comment, even though functionally that is exactly what it is.

=item metadata

This is data about the program. It should include the shebang line for
such formats as support it.

=item other

This is a catch-all category; you will have to consult the documentation
for the individual syntax filters to see what (if anything) gets put
into this category. Syntax filters should use this sparingly, if at all.

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

=head2 __get_peek_handle()

The L<__classify()|/__classify> method can call this method to get a
file handle to the input, in case it needs to read ahead to classify a
line. This method B<must not> be called from any other place.

After the L<__classify()|/__classify> method returns, the file handle's
position and Perl's line counter (C<$.>) will be restored.

See
L<App::AckX::Preflight::Syntax::Crystal|App::AckX::Preflight::Syntax::Crystal>
for a sample of how this is used.

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

=head2 __restore_file_position

 my $scope_guard => $self->__restore_file_position( $fh );

If a syntax filter decides to read the input file on its own behalf in
(e.g.) its L<__classify()|/__classify> method, it B<must> preserve and
restore the C<$.> variable and file position, and restore them when it
is done. One way to do this is to call this method and preserve the
returned lexical variable until scope exit. Destruction of the returned
object will do the required restoration.

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

=item all syntax type returned by L<__handles_syntax()|/__handles_syntax>
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

See C<--syntax-type> above.

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
