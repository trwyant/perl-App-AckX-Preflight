package App::AckX::Preflight::Syntax;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight::Util qw{
    :croak
    :syntax
    __syntax_types
    @CARP_NOT
};
use Module::Pluggable::Object 5.2;
use List::Util 1.45 ();	# for uniqstr
use Text::Abbrev ();

our $VERSION = '0.000_013';

our @EXPORT_OK = qw{
    __normalize_options
};

use constant IN_SERVICE		=> 1;
use constant IS_EXHAUSTIVE	=> 1;

use constant PLUGIN_SEARCH_PATH	=> __PACKAGE__;
use constant PLUGIN_MAX_DEPTH	=> do {
    my @parts = split qr{ :: }smx, PLUGIN_SEARCH_PATH;
    1 + @parts;
};

*__uniqstr = \&List::Util::uniqstr;	# sub __uniqstr {...}

my $arg_sep_re = qr{ \s* [:;,] \s* }smx;

sub __getopt {
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
    return $opt;
}

my %WANT_SYNTAX;
my %SYNTAX_OPT;

sub import {
    my ( $class, @arg ) = @_;
    my $opt = $class->__getopt( \@arg );
    %SYNTAX_OPT  = map { $_ => $opt->{$_} } qw{ syntax-type };
    %WANT_SYNTAX = map { $_ => 1 } @{ $opt->{syntax} || [] };
    foreach ( @{ $opt->{'syntax-mod'} || [] } ) {
	my ( $filter, $mod, @val ) = @{ $_ };
	$filter->__handles_type_mod( $mod, @val );
    }
    return;
}

sub __handles_syntax {
    __die_hard(
	'__handles_syntax() must be overridden' );
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
	$handles_type{$class} = [ __uniqstr( 
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
	$handles_type{$class} = [ __uniqstr( @arg ) ];
	return;
    }

}

{
    my $syntax_abbrev;

    sub __normalize_options {
	my ( $invocant, $opt ) = @_;

	$syntax_abbrev ||= Text::Abbrev::abbrev( __syntax_types() );

	my $class = ref $invocant || $invocant;

	if ( $opt->{syntax} ) {
	    @{ $opt->{syntax} } = sort { $a cmp $b } __uniqstr(
		map { $syntax_abbrev->{$_} || 
		    __die( "Unsupported syntax type '$_'" ) }
		map { split $arg_sep_re }
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
	    $val =~ s/ \A ( \w+ (?: :: \w+ )* ) $arg_sep_re? //smx
		or __die( "Invalid syntax filter name in -$name=$val" );
	    my $filter = $1;
	    $filter =~ m/ :: /smx
		or $filter = join '::', __PACKAGE__, $filter;
	}
	$plugins->{$filter}
	    or __die( "Unknown syntax filter $filter" );
	return ( $filter, $mod, split $arg_sep_re, $val );
    }
}

{
    my $mpo;

    sub __plugins {
	$mpo ||= Module::Pluggable::Object->new(
	    inner	=> 0,
	    max_depth	=> PLUGIN_MAX_DEPTH,
	    require	=> 1,
	    search_path	=> PLUGIN_SEARCH_PATH,
	);
	return (
	    grep {
		$_->IN_SERVICE &&
		m/ \b [[:alpha:]] \w* \z /smx
	    } $mpo->plugins() );
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

=head2 __getopt

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

The import list is parsed by L<__getopt()|/__getopt>. The import list
must be completely consumed by this operation, or an exception is
raised. All C<--syntax> arguments must be valid or an exception is
raised.

=head2 __handles_syntax

This static method returns a list of the syntax types recognized by the
filter. These can be anything, but for sanity's sake the following list
(or such members of it that apply) is recommended:

=over

=item code

This should be self-explanatory.

=item comment

This is comments, both single-line and block comments that occupy whole
lines. Inline documentation should be C<'doc'> if that can be managed.

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

See L<-syntax-type|/-syntax-type> above.

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

Copyright (C) 2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
