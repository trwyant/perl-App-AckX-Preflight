package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Cc;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Cc';

use constant CC_FILE	=> 't/data/cc_file.c';

use constant CC_CODE	=> <<'EOD';
   1: #include <stdio.h>
   2:
   4:
   5: int main ( int argc, char ** argv ) {
   6:     printf( "Hello %s!\n", argc > 1 ? argv[1] : "world" );
   7: }
   8:
EOD

use constant CC_COMMENTS	=> <<'EOD';
   3: /* This is a single-line block comment */
   9: /*
  10:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
  11:  *
  12:  * Copyright (C) 2018-2022 by Thomas R. Wyant, III
  13:  *
  14:  * This program is distributed in the hope that it will be useful, but
  15:  * without any warranty; without even the implied warranty of
  16:  * merchantability or fitness for a particular purpose.
  17:  *
  18:  * ex: set textwidth=72 :
  19:  */
EOD

use constant CC_CODE_COMMENTS => <<'EOD';
   1: #include <stdio.h>
   2:
   3: /* This is a single-line block comment */
   4:
   5: int main ( int argc, char ** argv ) {
   6:     printf( "Hello %s!\n", argc > 1 ? argv[1] : "world" );
   7: }
   8:
   9: /*
  10:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
  11:  *
  12:  * Copyright (C) 2018-2022 by Thomas R. Wyant, III
  13:  *
  14:  * This program is distributed in the hope that it will be useful, but
  15:  * without any warranty; without even the implied warranty of
  16:  * merchantability or fitness for a particular purpose.
  17:  *
  18:  * ex: set textwidth=72 :
  19:  */
EOD

$App::Ack::mappings{cc} = [
    App::Ack::Filter::Extension->new( qw{ c } ),
];

my $cc_resource = ACK_FILE_CLASS->new( CC_FILE );

my $text_resource = ACK_FILE_CLASS->new( TEXT_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ cc css less } ],
    sprintf '%s handles cc, css, less', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( CC_FILE ), CC_CODE, 'Only code, reading directly';

is slurp( $cc_resource ), CC_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( CC_FILE ), CC_COMMENTS, 'Only comments, reading directly';

is slurp( $cc_resource ), CC_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '--syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

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
