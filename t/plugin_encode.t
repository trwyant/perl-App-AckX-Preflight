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
is \@got, [ qw{ encoding=s@ } ], 'Options';

@got = CLASS->__peek_opt();
is \@got, [], 'Peek options';


@got = prs( qw{ --encoding=utf-8:type:perl } );
@want = ( { encoding => [ 'utf-8:type:perl' ] } );
is \@got, \@want,
    q<Parse --encoding=utf-8:type:perl'>;

@got = xqt( @want );
is \@got, [
    [ [ 'App::AckX::Preflight::Encode',
	    { encoding => [ [ qw{ utf-8 type perl } ] ] } ] ]
],
    q<Process --encoding=utf-8:type:perl'>;


@got = prs( qw{
    --encoding=utf-8:type:raku
    --encoding=latin-1:type:python
    --encoding=cp1252:is:windows.bat
    } );
@want = ( { encoding => [ qw{ utf-8:type:raku latin-1:type:python
	    cp1252:is:windows.bat } ] } );
is \@got, \@want,
    q<Parse '--encoding=utf-8:type:raku --encoding=latin-1:type:python --encoding=cp1252:is:windows.bat'>;

@got = xqt( @want );
is \@got, [
    [ [ 'App::AckX::Preflight::Encode',
	    { encoding => [
		    [ qw{ utf-8   type raku } ],
		    [ qw{ latin-1 type python } ],
		    [ qw{ cp1252  is   windows.bat } ],
		]
	    } ] ]
],
    q<Process '--encoding=utf-8:type:raku --encoding=latin-1:type:python --encoding=cp1252:is:windows.bat'>;


done_testing;

1;

# ex: set textwidth=72 :
