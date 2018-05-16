package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Lisp;
use App::AckX::Preflight::Util qw{ :syntax };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Lisp';

use constant LISP_FILE	=> 't/data/lisp_file.lisp';

use constant LISP_CODE	=> <<'EOD';
   1: #!/usr/bin/env clisp
   8: (
   9:  format t "Hello, world!~%"
  10: )
EOD

use constant LISP_COMMENT	=> <<'EOD';
   2: ; This is a comment
   4: #|
   5:  | Is this a comment? It seems so.
   6:  | #| Do they really nest? Yes. |#
   7:  |#
EOD

use constant LISP_DOC	=> <<'EOD';
   3: ;;; but this is documentation
EOD

use constant LISP_CODE_DOC => <<'EOD';
   1: #!/usr/bin/env clisp
   3: ;;; but this is documentation
   8: (
   9:  format t "Hello, world!~%"
  10: )
EOD

$App::Ack::mappings{lisp} = [
    App::Ack::Filter::Extension->new( qw{ lisp } ),
];

my $resource = App::Ack::Resource->new( LISP_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ clojure elisp lisp scheme } ],
    sprintf '%s handles clojure, elisp, lisp, scheme', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( LISP_FILE ), LISP_CODE, 'Only code, reading directly';

is slurp( $resource ), LISP_CODE, 'Only code, reading resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( LISP_FILE ), LISP_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), LISP_COMMENT, 'Only comments, reading resource';

SYNTAX_FILTER->import( '-syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( LISP_FILE ), LISP_DOC, 'Only documentation, reading directly';

is slurp( $resource ), LISP_DOC, 'Only documentation, reading resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( LISP_FILE ), LISP_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), LISP_CODE_DOC,
    'Code and documentation, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
