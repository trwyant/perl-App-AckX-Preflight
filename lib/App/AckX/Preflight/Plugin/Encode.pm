 package App::AckX::Preflight::Plugin::Encode;

use 5.010001;

use strict;
use warnings;
use parent qw{ App::AckX::Preflight::Plugin };

use App::AckX::Preflight::Util qw{
    :croak
    :ref
    __check_encoding
    @CARP_NOT
};

our $VERSION = '0.000_046';

use constant DISPATCH_PRIORITY	=> 100;

sub __options {
    return(
	'encoding=s', \&_option_encoding,
	'encoding_del|encoding-del=s', \&_option_encoding_del,
    );
}

sub _option_encoding {
    my ( undef, $val, $opt ) = @_;	# Name not used

    $opt = $opt->{encoding} ||= {};
    my ( $encoding, $filter, $arg ) = split /:/, $val, 3;
    state $handler = {
	ext	=> sub {
	    my ( $config, $arg, $encoding ) = @_;
	    foreach my $ext ( split /,/, $arg ) {
		$config->{ext}{$ext} = $encoding;
	    }
	    return;
	},
	is	=> sub {
	    my ( $config, $arg, $encoding ) = @_;
	    $config->{is}{$arg} = $encoding;
	    return;
	},
	match => sub {
	    my ( $config, $arg, $encoding ) = @_;
	    # Note we can't make a regex yet because this
	    # (potentially) has to be JSON-encoded.
	    state $order = 0;
	    $config->{match}{$arg} = [ $arg, $encoding, $order++ ];
	    return;
	},
	type	=> sub {
	    my ( $config, $arg, $encoding ) = @_;
	    $config->{type}{$arg} = $encoding;
	    return;
	},
    };
    my $code = $handler->{$filter}
	or __die( "Unknown filter '$filter'" );
    $code->( $opt, $arg, $encoding );
    return;
}

sub _option_encoding_del {
    my ( undef, $val, $opt ) = @_;	# Name not used
    $opt = $opt->{encoding} ||= {};
    my ( $filter, $arg ) = split /:/, $val, 2;
    delete $opt->{$filter}{$arg};
    return;
}

sub __process {
    my ( undef, $aaxp, $opt ) = @_;

    defined $opt->{$_} or delete $opt->{$_} for keys %{ $opt };

    foreach my $key ( keys %{ $opt->{encoding} } ) {
	my $ref = ref $opt->{encoding}{$key}
	    or next;
	state $handler = {
	    ARRAY_REF, sub {
		my ( $elem ) = @_;
		return !! @{ $elem };
	    },
	    HASH_REF, sub {
		my ( $elem ) = @_;
		return !! keys %{ $elem };
	    },
	};
	my $code = $handler->{$ref} || sub { 1 };
	$code->( $opt->{encoding}{$key} )
	    or delete $opt->{encoding}{$key};
    }

    keys %{ $opt->{encoding} }
	or delete $opt->{encoding};

    keys %{ $opt }
	or return;

    keys %{ $opt->{encoding}{match} || {} }
	and $opt->{encoding}{match} = [ sort { $a->[2] <=> $b->[2] }
	values %{ $opt->{encoding}{match} } ];

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

=head1 OPTIONS

This plug-in recognizes and processes the following options:

=head2 --encoding

 --encoding cp1252:is:c:/windows.bat
 --encodomg latin-1:match:\.py$
 --encoding utf-8:type:perl

This option specifies the encoding to be applied to a specific file or
class of files. The value is three colon-delimited values: the encoding,
the rule, and the argument for the rule (which varies based on the rule).

The parse allows colons in the argument.

If there is only one colon, the rule is assumed to be C<'is'>, and the
value of the option specifies the encoding and the argument. So
C<--encoding=utf-8:fubar.PL> is equivalent to
C<--encoding=utf-8:is:fubar.PL>.

Valid rules are:

=over

=item ext

This rule specifies all files having a given file name extension.
Multiple comma-delimited extensions can be specified. For example, a
possible way to specify most Perl files would be

 --encoding=utf-8:ext:pl,PL,pm,t

=item is

This rule specifies an individual file. The argument is the path to the
file.

=item match

The argument to this rule is a regular expression. The rule specifies
any file whose name matches the regular expression.

=item type

This rule specifies an F<ack> file type. The argument is the specific
type.

=back

B<Note> that although the syntax looks like that of an F<ack> filter
rule, L<App::Ack::Filter|App::Ack::Filter> objects are B<not> used to
match encodings to files.

=head2 --encoding-del

 --encoding-del match:\.py$

This option deletes the encoding associated with the specified rule and
argument. No error or warning is generated if the rule and argument have
not been specified.

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
