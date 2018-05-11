package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Cc;
use App::AckX::Preflight::Util qw{ :syntax };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Cc';

use constant CC_FILE	=> 't/data/cc_file.c';

use constant CC_CODE	=> <<'EOD';
   1: #include <stdio.h>
   2:
   3: int main ( int argc, char ** argv ) {
   4:     printf( "Hello, %s!\n", argc > 1 ? argv[1] : "world" );
   5: }
   6:
EOD

use constant CC_COMMENTS	=> <<'EOD';
   7: /*
   8:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   9:  *
  10:  * Copyright (C) 2018 by Thomas R. Wyant, III
  11:  *
  12:  * This program is distributed in the hope that it will be useful, but
  13:  * without any warranty; without even the implied warranty of
  14:  * merchantability or fitness for a particular purpose.
  15:  *
  16:  * ex: set textwidth=72 :
  17:  */
EOD

use constant CC_CODE_COMMENTS => <<'EOD';
   1: #include <stdio.h>
   2:
   3: int main ( int argc, char ** argv ) {
   4:     printf( "Hello, %s!\n", argc > 1 ? argv[1] : "world" );
   5: }
   6:
   7: /*
   8:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   9:  *
  10:  * Copyright (C) 2018 by Thomas R. Wyant, III
  11:  *
  12:  * This program is distributed in the hope that it will be useful, but
  13:  * without any warranty; without even the implied warranty of
  14:  * merchantability or fitness for a particular purpose.
  15:  *
  16:  * ex: set textwidth=72 :
  17:  */
EOD

$App::Ack::mappings{cc} = [
    App::Ack::Filter::Extension->new( qw{ c } ),
];

my $cc_resource = App::Ack::Resource->new( CC_FILE );

my $text_resource = App::Ack::Resource->new( TEXT_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ], [ qw{ cc css } ],
    sprintf '%s handles cc, css', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( CC_FILE ), CC_CODE, 'Only code, reading directly';

is slurp( $cc_resource ), CC_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( CC_FILE ), CC_COMMENTS, 'Only comments, reading directly';

is slurp( $cc_resource ), CC_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( CC_FILE ), CC_CODE_COMMENTS,
    'Code and comments, reading directly';

is slurp( $cc_resource ), CC_CODE_COMMENTS,
    'Code and comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and comments, text resource';

done_testing;

1;

# ex: set textwidth=72 :
