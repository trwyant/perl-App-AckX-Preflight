package App::AckX::Preflight::Syntax;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Util
    qw{
	:croak
	:ref
	:syntax
	__load
	__set_sub_name
	__syntax_types
	ACK_FILE_CLASS
	@CARP_NOT
    };
use Exporter qw{ import };
use Fcntl qw{ :seek };
use List::Util 1.45 ();	# for uniqstr
use Scope::Guard ();
use Text::Abbrev ();

# This is PRIVATE to the App-AckX-Preflight package.
our @EXPORT_OK = qw{ __normalize_options };

our $VERSION = '0.000_044';

my $ARG_SEP_RE = qr{ \s* [:;,] \s* }smx;

use constant IN_SERVICE		=> 1;
use constant IS_EXHAUSTIVE	=> 1;

use constant PLUGIN_MATCH	=> qr< \A @{[ __PACKAGE__ ]} :: [A-Z] >smxi;

my %WANT_SYNTAX;
my %SYNTAX_OPT;


sub __handles_file {
    my ( $self, $rsrc ) = @_;
    unless ( keys %App::Ack::mappings ) {
	# Hide these from xt/author/prereq.t, since we do not execute
	# this code when called from the hot patch, which is the normal
	# path through the code. It is needed for (e.g.) tools/number.
	__load( $_ ) for qw{
	    App::Ack::ConfigLoader
	    App::Ack::Filter
	    App::Ack::Filter::Default
	    App::Ack::Filter::Extension
	    App::Ack::Filter::FirstLineMatch
	    App::Ack::Filter::Inverse
	    App::Ack::Filter::Is
	    App::Ack::Filter::IsPath
	    App::Ack::Filter::Match
	    App::Ack::Filter::Collection
	};
	my @arg_sources = App::Ack::ConfigLoader::retrieve_arg_sources();
	App::Ack::ConfigLoader::process_args( @arg_sources );
    }
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

sub __help_syntax {
    my %syntax;
    my $len = 0;
    foreach my $filter ( __PACKAGE__->__plugins() ) {
	( my $name = $filter ) =~ s/ .* :: //smx;
	foreach my $type ( $filter->__handles_type() ) {
	    $len = List::Util::max( $len, length $type );
	    push @{ $syntax{$type} ||= [] }, $name;
	}
    }
    foreach my $type ( sort keys %syntax ) {
	say sprintf '%-*s  %s', $len, $type, "@{ $syntax{$type} }";
    }
    exit;
}

sub __main_parser_options {
    return(
	'help_syntax|help-syntax'	=> \&__help_syntax,
	qw{
	syntax=s@
	syntax_match|syntax-match!
	syntax_type|syntax-type!
	syntax_wc|syntax-wc!
	syntax_wc_only|syntax-wc-only!
    } );
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

sub __new {
    my ( $class, $opt ) = @_;
    $opt ||= $class->__syntax_opt();
    my $self = bless {}, ref $class || $class;
    my $attr = $self->__my_attr();
    $attr->{syntax_empty_code_is_comment} =
	$opt->{syntax_empty_code_is_comment};
    $attr->{syntax_type} = $opt->{syntax_type};
    $attr->{want} = $opt->{syntax} || $self->__want_syntax();
    $opt->{syntax_wc}
	and $attr->{syntax_wc} = {};
    $attr->{syntax_wc_only} = $opt->{syntax_wc_only};
    $self->__init();
    return $self;
}

sub PUSHED {
#   my ( $class, $mode, $fh ) = @_;
    my ( $class ) = @_;

    my $self = $class->__new();

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

sub __normalize_options {
    my ( $invocant, $opt ) = @_;

    state $syntax_abbrev = Text::Abbrev::abbrev( __syntax_types(), 'none' );

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

sub _normalize_syntax_mod {
    my ( $invocant, $spec ) = @_;

    state $plugins = { map { $_ => 1 } $invocant->__plugins() };

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

sub __plugins {
    my @rslt;
    foreach my $plugin ( @CARP_NOT ) {
	$plugin =~ PLUGIN_MATCH
	    or next;
	__load( $plugin )
	    or next;
	$plugin->IN_SERVICE()
	    or next;
	push @rslt, $plugin;
    }
    return @rslt;
}

sub __syntax_opt {
    return \%SYNTAX_OPT;
}

sub __want_everything {
    my ( $class ) = @_;
    $class->IS_EXHAUSTIVE
	or return;
    my $want_syntax = $class->__want_syntax();
    keys %{ $want_syntax }
	or return 1;
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

sub __get_syntax_filter {
    my ( undef, $file ) = @_;
    unless ( ref $file ) {
	__load( ACK_FILE_CLASS )
	    or __die_hard( sprintf 'Can not load %s', ACK_FILE_CLASS );
	$file = ACK_FILE_CLASS->new( $file );
    }

    foreach my $syntax ( __PACKAGE__->__plugins() ) {
	$syntax->__handles_file( $file )
	    and return $syntax;
    }

    return undef;	## no critic (ProhibitExplicitReturnUndef)
}

# New App::AckX::Preflight::FileMonkey interface
# TODO if this goes in. at least __want_everything goes away. And maybe
# __new() becomes empty, since the configuration is available via
# closure rather than being stored locally.
sub __setup {
    my ( $class, $config, $fh, $file ) = @_;	# Invocant unused

    # If the caller is a resource or a filter we're not opening for
    # the main scan. Just use the normal machinery.
    my ( $caller ) = caller 1;	# We want our caller's caller
    # NOTE that the only known way for $caller to be undefined is during
    # testing.
    if ( defined $caller ) {
	foreach my $c ( ACK_FILE_CLASS, qw{ App::Ack::Filter } ) {
	    $caller->isa( $c )
		and return;
	}
    }

    # Figure out which syntax filter we are using. If none, just return.
    # NOTE that the only known way to call this on an actual syntax
    # filter is during testing.
    my $syntax;
    if ( $class eq __PACKAGE__ ) {
	defined( $syntax = __PACKAGE__->__get_syntax_filter( $file ) )
	    or return;
    } else {
	$syntax = $class;
    }

    # Modify syntax types as needed
    foreach my $key ( qw{ syntax_del syntax_set syntax_add } ) {
	my $val = delete $config->{$key}
	    or next;
	( my $mod = $key ) =~ s/ .* _ //smx;
	ref $val eq ARRAY_REF
	    or $val = [ $val ];
	my $code = $class->can( "_handles_type_$mod" )
	    or __die_hard( "Invalid modification type '$mod'" );
	$code->( $class, @{ $val } );
    }

    # Stash the configuration
    %WANT_SYNTAX = map { $_ => 1 } @{ $config->{syntax} || [] };
    %SYNTAX_OPT = %{ $config };
    $SYNTAX_OPT{syntax} = \%WANT_SYNTAX;

    # If we want everything and we're not reporting syntax types or
    # word count we don't need the filter.
    # my $want_syntax;

    WANT_SYNTAX: {
	if ( $config->{syntax_type} || $config->{syntax_wc} ) {
	    keys %WANT_SYNTAX
		or %WANT_SYNTAX = map { $_ => 1 } $syntax->__handles_syntax();
	} else {
	    keys %WANT_SYNTAX
		or return;
	    foreach my $type ( $syntax->__handles_syntax() ) {
		$WANT_SYNTAX{$type}
		    or last WANT_SYNTAX;
	    }
	    return;
	}
    }

    # NOTE that the only known way $fh can be undefined is during
    # testing.
    $fh
	or return;

    # Check to see if we're already on the PerlIO stack. If so, just
    # return the file handle. The original open() is idempotent, and
    # ack makes use of this, so we have to be idempotent also.
    foreach my $layer ( PerlIO::get_layers( $fh ) ) {
	$layer =~ SYNTAX_FILTER_LAYER
	    and return $fh;
    }

    # Insert the correct syntax filter into the PerlIO stack.
    binmode $fh, ":via($syntax)";

    return;
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

=head2 __get_syntax_filter

This static method is passed either a file name or an
L<App::Ack::File|App::Ack::File> object. It returns the fully-qualified
class name of the C<App::AckX::Preflight> syntax filter that processes
the file, or C<undef> if none can be found. The requisite syntax filter
will have been loaded.

=head2 __handles_file

This static convenience method takes as its argument an
L<App::Ack::File|App::Ack::File> object and returns a true value if this
syntax filter handles the file.  Otherwise it returns a false value.

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

=head2 __main_parser_options

This static method centralize the options that need to be seen by the
main command line parser. These are C<--syntax>, C<--syntax-match>,
C<--syntax-type>, C<--syntax-wc>, and C<--syntax-wc-only>.

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

=head2 __want_everything

 $syntax_filter->__want_everything()
   and return;

This static method determines whether, given the syntax types actually
requested, a given syntax filter would pass all lines in any conceivable
file. It returns a true value if and only if all of the following
conditions are true:

=over

=item L<IS_EXHAUSTIVE|/IS_EXHAUSTIVE> is true;

=item L<__want_syntax()|/__want_syntax> returns an empty hash, -OR-

=item all syntax type returned by L<__handles_syntax()|/__handles_syntax> appear in the hash returned by L<__want_syntax()|/__want_syntax>.

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

Copyright (C) 2018-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
