package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Ocaml;
use Test2::V0 -target => {
    SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Ocaml' };

use lib qw{ inc };
use My::Module::TestSyntax;

use constant OCAML_FILE	=> 't/data/ocaml_file.ml';

use constant OCAML_CODE	=> <<'EOD';
   3:
   4: open Printf
   5:
  10:
  13:
  14: let name = if Array.length Sys.argv > 1
  15:     then Sys.argv.(1)
  16:     else "world";;
  17: printf "Hello %s!\n" name;;
EOD

use constant OCAML_COMMENT	=> <<'EOD';
   6: (* This is a comment
   7:  * (* Note that comments nest *)
   8:  * so that this is still a comment *)
   9: (*** This is a comment, rather than documentation *)
EOD

use constant OCAML_DOC	=> <<'EOD';
   2: (** This is documentation for the entire file *)
  11: (** This is more
  12:  * documentation *)
EOD

use constant OCAML_CODE_DOC => <<'EOD';
   2: (** This is documentation for the entire file *)
   3:
   4: open Printf
   5:
  10:
  11: (** This is more
  12:  * documentation *)
  13:
  14: let name = if Array.length Sys.argv > 1
  15:     then Sys.argv.(1)
  16:     else "world";;
  17: printf "Hello %s!\n" name;;
EOD

setup_slurp(
    type	=> 'ocaml',
    extension	=> 'ml',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( OCAML_FILE );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ ocaml } ],
    sprintf '%s handles ocaml', SYNTAX_FILTER;

setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( OCAML_FILE ), OCAML_CODE, 'Only code, reading directly';

is slurp( $resource ), OCAML_CODE, 'Only code, reading resource';

setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( OCAML_FILE ), OCAML_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), OCAML_COMMENT, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_DOCUMENTATION ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( OCAML_FILE ), OCAML_DOC, 'Only documentation, reading directly';

is slurp( $resource ), OCAML_DOC, 'Only documentation, reading resource';

setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_DOCUMENTATION ] );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( OCAML_FILE ), OCAML_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), OCAML_CODE_DOC,
    'Code and documentation, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
