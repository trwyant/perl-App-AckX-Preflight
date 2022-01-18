package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Cpp;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Cpp';

use constant CPP_FILE	=> 't/data/cpp_file.cpp';

use constant CPP_CODE	=> <<'EOD';
   1: #include <stdio.h>
   2:
   3: using namespace std;
   4:
   9:
  10: int main( int argc, char *argv[] ) {
  11:
  14:     printf( "Hello %s!\n", argc > 1 ? argv[1] : "world" );
  15:
  16:     return 0;
  17: }
  18:
EOD

use constant CPP_COMMENT	=> <<'EOD';
  12:     /* Old-school printf still works. */
  13:     // As do new-school C++ comments
  19: /*
  20:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
  21:  *
  22:  * Copyright (C) 2018-2022 by Thomas R. Wyant, III
  23:  *
  24:  * This program is distributed in the hope that it will be useful, but
  25:  * without any warranty; without even the implied warranty of
  26:  * merchantability or fitness for a particular purpose.
  27:  *
  28:  * ex: set textwidth=72 :
  29:  */
EOD

use constant CPP_DOC	=> <<'EOD';
   5: /**
   6:  * Print the standard 'Hello, world!' message. If a command argument is
   7:  * passed, it is used instead of 'world.'
   8:  */
EOD

use constant CPP_CODE_DOC => <<'EOD';
   1: #include <stdio.h>
   2:
   3: using namespace std;
   4:
   5: /**
   6:  * Print the standard 'Hello, world!' message. If a command argument is
   7:  * passed, it is used instead of 'world.'
   8:  */
   9:
  10: int main( int argc, char *argv[] ) {
  11:
  14:     printf( "Hello %s!\n", argc > 1 ? argv[1] : "world" );
  15:
  16:     return 0;
  17: }
  18:
EOD

$App::Ack::mappings{cpp} = [
    App::Ack::Filter::Extension->new( qw{ cpp } ),
];

my $resource = ACK_FILE_CLASS->new( CPP_FILE );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ actionscript cpp dart go hh hpp js kotlin objc objcpp sass stylus } ],
    sprintf '%s handles actionscript, cpp, dart, go, hh, hpp, js, kotlin, objc, objcpp, sass, stylus', SYNTAX_FILTER;


SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( CPP_FILE ), CPP_CODE, 'Only code, reading directly';

is slurp( $resource ), CPP_CODE, 'Only code, reading resource';


SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( CPP_FILE ), CPP_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), CPP_COMMENT, 'Only comments, reading resource';


SYNTAX_FILTER->import( '-syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( CPP_FILE ), CPP_DOC, 'Only documentation, reading directly';

is slurp( $resource ), CPP_DOC, 'Only documentation, reading resource';


SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( CPP_FILE ), CPP_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), CPP_CODE_DOC,
    'Code and documentation, reading resource';


done_testing;

1;

# ex: set textwidth=72 :
