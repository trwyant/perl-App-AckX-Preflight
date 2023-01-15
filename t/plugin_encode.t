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


@got = grep { ! ref } CLASS->__options();
is \@got, [ qw{ encoding=s encoding_del|encoding-del=s } ], 'Options';

@got = CLASS->__peek_opt();
is \@got, [], 'Peek options';


@got = prs( qw{ --encoding=utf-8:type:perl } );
@want = ( { encoding => {
	    type	=> {
		perl	=> 'utf-8',
	    },
	},
    },
);
is \@got, \@want,
    q<Parse --encoding=utf-8:type:perl'>;

@got = xqt( @want );
is \@got, [
    [ [ 'App::AckX::Preflight::Encode', { encoding => {
		    type	=> {
			perl => 'utf-8',
		    },
		},
	    },
	] ],
], q<Process --encoding=utf-8:type:perl'>;


@got = do {
    no warnings qw{ qw };
    prs( qw{
	--encoding=utf-8:type:raku
	--encoding=ascii:ext:c,h
	--encoding=latin-1:match:\.java$
	--encoding=latin-1:match:\.py$
	--encoding=cp1252:is:c:/windows.bat
	--encoding-del=match:\.java$
	} );
};
@want = ( { encoding => {
	    ext		=> {
		c	=> 'ascii',
		h	=> 'ascii',
	    },
	    is		=> {
		'c:/windows.bat'	=> 'cp1252',
	    },
	    match	=> {
		'\.py$'	=> [ '\.py$', 'latin-1', 1 ],
	    },
	    type	=> {
		raku	=> 'utf-8',
	    },
	},
    },
);
is \@got, \@want,
    q<Parse '--encoding=utf-8:type:raku --encoding=latin-1:match:\.py$ --encodincp1252:is:c:/windows.bat'>;

@got = xqt( @want );
is \@got, [
    [ [ 'App::AckX::Preflight::Encode', { encoding => {
		    ext	=> {
			c	=> 'ascii',
			h	=> 'ascii',
		    },
		    is	=> { 'c:/windows.bat' => 'cp1252' },
		    match => [
			[ qw{ \.py$ latin-1  1 } ],
		    ],
		    type => {
			raku	=> 'utf-8',
		    },
		}
	    } ] ]
], q<Process '--encoding=utf-8:type:raku --encoding=latin-1:match:\.py$ --encodincp1252:is:c:/windows.bat'>;


done_testing;

1;

# ex: set textwidth=72 :
