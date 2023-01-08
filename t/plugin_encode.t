package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use Getopt::Long;
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::Encode';

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

my @got;
my @want;


@got = CLASS->__options();
is \@got,
[ qw{
    encode_file|encode-file=s%
    encode_type|encode-type=s%
    encoding=s@
    } ],
'Options';

@got = CLASS->__peek_opt();
is \@got, [], 'Peek options';


@got = prs( qw{ --encode-type=perl=utf-8 } );
@want = ( { encode_type => { perl => 'utf-8' } } );
is \@got, \@want,
q<Parse '--encode-type=perl=utf-8'>;

@got = xqt( @want );
is \@got, [
    [ [ 'App::AckX::Preflight::Encode',
	    { encoding => [ [ qw{ utf-8 type perl } ] ] } ] ]
],
q<Process '--encode-type=perl=utf-8'>;


@got = prs( qw{
    --encode-type=raku=utf-8
    --encode-type python=latin-1
    --encode-file=windows.bat=cp1252
    } );
@want = ( {
	encode_file	=> {
	    'windows.bat', 'cp1252',
	},
	encode_type	=> {
	    raku	=> 'utf-8',
	    python	=> 'latin-1',
	},
    } );
is \@got, \@want,
q<Parse '--encode-type=raku=utf-8 --encode-type python=latin-1 --encode-file=windows.bat=cp1252'>;

@got = xqt( @want );
is \@got, [
    [ [ 'App::AckX::Preflight::Encode',
	    { encoding => [
		    [ qw{ cp1252  is   windows.bat } ],
		    [ qw{ latin-1 type python } ],
		    [ qw{ utf-8   type raku } ],
		]
	    } ] ]
],
q<Process '--encode-type=perl=utf-8'>;


done_testing;

1;

# ex: set textwidth=72 :
