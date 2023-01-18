package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Make;
use Test2::V0 -target => 'App::AckX::Preflight::Syntax::Make';
use constant SYNTAX_FILTER => CLASS;

use lib qw{ inc };
use My::Module::TestSyntax;

use constant MAKE_FILE	=> 't/data/make_file.mak';

use constant MAKE_CODE	=> <<'EOD';
   3:
   4: greeting:
   5: 	echo 'Hello ' \
   6: 	    'world!'
EOD

use constant MAKE_COMMENTS	=> <<'EOD';
   1: # This is not a Makefile to make anything; it is just to test the \
   2:     Makefile syntax filter.
EOD

use constant MAKE_CODE_COMMENT => <<'EOD';
   1: # This is not a Makefile to make anything; it is just to test the \
   2:     Makefile syntax filter.
   3:
   4: greeting:
   5: 	echo 'Hello ' \
   6: 	    'world!'
EOD

setup_slurp(
    type	=> 'make',
    extension	=> 'mak',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( MAKE_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ make tcl } ],
    sprintf '%s handles make, tcl', SYNTAX_FILTER;

setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( MAKE_FILE ), MAKE_CODE, 'Only code, reading directly';

is slurp( $resource ), MAKE_CODE, 'Only code, reading resource';

setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( MAKE_FILE ), MAKE_COMMENTS, 'Only comments, reading directly';

is slurp( $resource ), MAKE_COMMENTS, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_COMMENT ] );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( MAKE_FILE ), MAKE_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $resource ), MAKE_CODE_COMMENT,
    'Code and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
