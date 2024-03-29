package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Util qw{ :syntax };
use App::AckX::Preflight::Syntax;
use Test2::V0 -target => 'App::AckX::Preflight::Plugin::Syntax';

use lib qw{ inc };
use My::Module::TestPlugin;	# Imports prs() and xqt()

my @got;
my @want;


@got = grep { ! ref } CLASS->__options();
is \@got,
    [
	qw{
	    help_syntax|help-syntax
	    syntax=s@
	    syntax_match|syntax-match!
	    syntax_type|syntax-type!
	    syntax_wc|syntax-wc!
	    syntax_wc_only|syntax-wc-only!
	},
    ],
    'Options';


@got = CLASS->__peek_opt();
is \@got, [ qw{ match=s } ],
    'Peek options';


@got = prs( qw{ --syntax code } );
@want = ( { syntax => [ SYNTAX_CODE ] } ); 
is \@got, \@want,
    q<Parse '--syntax code'>;


@got = prs( qw{ --syntax code --fubar baz } );
@want = ( { syntax => [ SYNTAX_CODE ] }, qw{ --fubar baz } ); 
is \@got, \@want,
    q<Parse '--syntax code --fubar baz'>;


@got = prs( '--syntax=code,doc' );
@want = ( { syntax => [ SYNTAX_CODE, SYNTAX_DOCUMENTATION ] } ); 
is \@got, \@want,
    q<Parse '--syntax=code,doc'>;


@got = prs( qw{ --syntax code --syntax doc --syntax data:code } );
@want = ( { syntax => [ SYNTAX_CODE, SYNTAX_DATA, SYNTAX_DOCUMENTATION ] } ); 
is \@got, \@want,
    q<Parse '--syntax code --syntax doc --syntax data:code'>;


done_testing;

1;

# ex: set textwidth=72 :
