package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Lisp;
use Test2::V0 -target => 'App::AckX::Preflight::Syntax::Lisp';
use constant SYNTAX_FILTER => CLASS;

use lib qw{ inc };
use My::Module::TestSyntax;

use constant LISP_FILE	=> 't/data/lisp_file.lisp';

use constant LISP_CODE	=> <<'EOD';
   9: (
  10:   format t "Hello ~a!~%" (
  11:     if ( > ( length *args* ) 0 ) ( first *args* ) "world"
  12:   )
  13: )
EOD

use constant LISP_COMMENT	=> <<'EOD';
   2: ; This is a comment
   4: #|
   5:  | Is this a comment? It seems so.
   6:  | #| Do they really nest? |#
   7:  | Yes. This is still a comment.
   8:  |#
EOD

use constant LISP_DOC	=> <<'EOD';
   3: ;;; but this is documentation
EOD

use constant LISP_CODE_DOC => <<'EOD';
   3: ;;; but this is documentation
   9: (
  10:   format t "Hello ~a!~%" (
  11:     if ( > ( length *args* ) 0 ) ( first *args* ) "world"
  12:   )
  13: )
EOD

setup_slurp(
    type	=> 'lisp',
    extension	=> 'lisp',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( LISP_FILE );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ clojure elisp lisp scheme } ],
    sprintf '%s handles clojure, elisp, lisp, scheme', SYNTAX_FILTER;

### setup_syntax( syntax => [ SYNTAX_CODE ] );
setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( LISP_FILE ), LISP_CODE, 'Only code, reading directly';

is slurp( $resource ), LISP_CODE, 'Only code, reading resource';

setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( LISP_FILE ), LISP_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), LISP_COMMENT, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_DOCUMENTATION ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( LISP_FILE ), LISP_DOC, 'Only documentation, reading directly';

is slurp( $resource ), LISP_DOC, 'Only documentation, reading resource';

setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_DOCUMENTATION ] );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( LISP_FILE ), LISP_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), LISP_CODE_DOC,
    'Code and documentation, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
