package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Haskell;
use Test2::V0 -target => {
    SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Haskell' };

use lib qw{ inc };
use My::Module::TestSyntax;

use constant HASKELL_FILE	=> 't/data/haskell_file.hs';

use constant HASKELL_CODE	=> <<'EOD';
   4:
   5: import System.Environment
   6: import System.IO
   7: import Text.Printf
   8:
  12:
  13: main = do
  14:     args <- getArgs
  15:     if length args > 0
  16:     then putStrLn( printf "Hello %s!" $ head args )
  17:     else putStrLn "Hello world!"
  21:
EOD

use constant HASKELL_COMMENT	=> <<'EOD';
   1: {-
   2:  - This is a block comment
   3:  -}
  18: -- This is a comment
  22: -- But this is a comment
EOD

use constant HASKELL_DOC	=> <<'EOD';
   9: {- |This program prints "Hello, world,"
  10:  - and this text documents the fact
  11:  -}
  19: -- | But this is documentation
  20: -- and this is documentation also.
EOD

use constant HASKELL_CODE_DOC => <<'EOD';
   4:
   5: import System.Environment
   6: import System.IO
   7: import Text.Printf
   8:
   9: {- |This program prints "Hello, world,"
  10:  - and this text documents the fact
  11:  -}
  12:
  13: main = do
  14:     args <- getArgs
  15:     if length args > 0
  16:     then putStrLn( printf "Hello %s!" $ head args )
  17:     else putStrLn "Hello world!"
  19: -- | But this is documentation
  20: -- and this is documentation also.
  21:
EOD

setup_slurp(
    type	=> 'haskell',
    extension	=> 'hs',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( HASKELL_FILE );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ haskell } ],
    sprintf '%s handles haskell', SYNTAX_FILTER;


setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( HASKELL_FILE ), HASKELL_CODE, 'Only code, reading directly';

is slurp( $resource ), HASKELL_CODE, 'Only code, reading resource';


setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( HASKELL_FILE ), HASKELL_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), HASKELL_COMMENT, 'Only comments, reading resource';


setup_syntax( syntax => [ SYNTAX_DOCUMENTATION ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( HASKELL_FILE ), HASKELL_DOC, 'Only documentation, reading directly';

is slurp( $resource ), HASKELL_DOC, 'Only documentation, reading resource';


setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_DOCUMENTATION ] );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( HASKELL_FILE ), HASKELL_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), HASKELL_CODE_DOC,
    'Code and documentation, reading resource';


done_testing;

1;

# ex: set textwidth=72 :
