package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Csharp;
use Test2::V0 -target => 'App::AckX::Preflight::Syntax::Csharp';
use constant SYNTAX_FILTER => CLASS;

use lib qw{ inc };
use My::Module::TestSyntax;

use constant CSHARP_FILE	=> 't/data/csharp_file.cs';

use constant CSHARP_CODE	=> <<'EOD';
   1: #include <stdio.h>
   2:
   7:
   8: int main ( int argc, char ** argv ) {
   9:     printf( "Hello %s!\n", argc > 1 ? argv[1] : "world" );
  10: }
  11:
EOD

use constant CSHARP_COMMENT	=> <<'EOD';
   3: // This is single-line comment
   6: /* This is a single-line block comment */
  12: /*
  13:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
  14:  *
  15:  * Copyright (C) 2018-2023 by Thomas R. Wyant, III
  16:  *
  17:  * This program is distributed in the hope that it will be useful, but
  18:  * without any warranty; without even the implied warranty of
  19:  * merchantability or fitness for a particular purpose.
  20:  *
  21:  * ex: set textwidth=72 :
  22:  */
EOD

use constant CSHARP_DOC	=> <<'EOD';
   4: /// But this is documentation. It is supposed to be in XML, but I am not
   5: /// going to bother with that.
EOD

use constant CSHARP_CODE_COMMENT_DOC => <<'EOD';
   1: #include <stdio.h>
   2:
   3: // This is single-line comment
   4: /// But this is documentation. It is supposed to be in XML, but I am not
   5: /// going to bother with that.
   6: /* This is a single-line block comment */
   7:
   8: int main ( int argc, char ** argv ) {
   9:     printf( "Hello %s!\n", argc > 1 ? argv[1] : "world" );
  10: }
  11:
  12: /*
  13:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
  14:  *
  15:  * Copyright (C) 2018-2023 by Thomas R. Wyant, III
  16:  *
  17:  * This program is distributed in the hope that it will be useful, but
  18:  * without any warranty; without even the implied warranty of
  19:  * merchantability or fitness for a particular purpose.
  20:  *
  21:  * ex: set textwidth=72 :
  22:  */
EOD

setup_slurp(
    type	=> 'csharp',
    extension	=> 'cs',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( CSHARP_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ csharp } ],
    sprintf '%s handles csharp', SYNTAX_FILTER;

setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( CSHARP_FILE ), CSHARP_CODE, 'Only code, reading directly';

is slurp( $resource ), CSHARP_CODE, 'Only code, reading resource';

setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( CSHARP_FILE ), CSHARP_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), CSHARP_COMMENT, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_DOCUMENTATION ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( CSHARP_FILE ), CSHARP_DOC, 'Only comments, reading directly';

is slurp( $resource ), CSHARP_DOC, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_COMMENT,
	SYNTAX_DOCUMENTATION ] );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT,
    SYNTAX_DOCUMENTATION;

is slurp( CSHARP_FILE ), CSHARP_CODE_COMMENT_DOC,
    'Code and comments, reading directly';

is slurp( $resource ), CSHARP_CODE_COMMENT_DOC,
    'Code and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
