package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Pascal;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Pascal';

use constant PASCAL_FILE	=> 't/data/pascal_file.pas';

use constant PASCAL_CODE	=> <<'EOD';
   5:
  10:
  14:
  15: program Hello;
  16: var
  17:     name : String;
  18: begin
  19:     if ( ParamCount > 0 )
  20:     then name := ParamStr( 1 )
  21:     else name := 'world';
  22:     writeln( 'Hello, ' + name + '!' );
  23: end.
EOD

use constant PASCAL_COMMENT	=> <<'EOD';
   1: (*
   2:  * This is an old-style comment. The syntax is exactly the same as "C"
   3:  * except for the use of matching parentheses rather than slashes.
   4:  *)
   6: {
   7:    This is a Turbo Pascal comment. Again the syntax is like "C", except
   8:    for the use of matching braces rather than '/* ... */'
   9: }
  11: // This is a Delphi comment, although Vims syntax highlighter appears
  12: // not to know this, necessitating the elimination of the apostrophe
  13: // in 'Vims'.
EOD

use constant PASCAL_CODE_COMMENT => <<'EOD';
   1: (*
   2:  * This is an old-style comment. The syntax is exactly the same as "C"
   3:  * except for the use of matching parentheses rather than slashes.
   4:  *)
   5:
   6: {
   7:    This is a Turbo Pascal comment. Again the syntax is like "C", except
   8:    for the use of matching braces rather than '/* ... */'
   9: }
  10:
  11: // This is a Delphi comment, although Vims syntax highlighter appears
  12: // not to know this, necessitating the elimination of the apostrophe
  13: // in 'Vims'.
  14:
  15: program Hello;
  16: var
  17:     name : String;
  18: begin
  19:     if ( ParamCount > 0 )
  20:     then name := ParamStr( 1 )
  21:     else name := 'world';
  22:     writeln( 'Hello, ' + name + '!' );
  23: end.
EOD

$App::Ack::mappings{delphi} = [
    App::Ack::Filter::Extension->new( qw{ pas } ),
];

my $resource = ACK_FILE_CLASS->new( PASCAL_FILE );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ delphi pascal } ],
    sprintf '%s handles delphi, pascal', SYNTAX_FILTER;


SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( PASCAL_FILE ), PASCAL_CODE, 'Only code, reading directly';

is slurp( $resource ), PASCAL_CODE, 'Only code, reading resource';


SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( PASCAL_FILE ), PASCAL_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), PASCAL_COMMENT, 'Only comments, reading resource';


SYNTAX_FILTER->import( '--syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( PASCAL_FILE ), PASCAL_CODE_COMMENT,
    'Code and documentation, reading directly';

is slurp( $resource ), PASCAL_CODE_COMMENT,
    'Code and documentation, reading resource';


done_testing;

1;

# ex: set textwidth=72 :
