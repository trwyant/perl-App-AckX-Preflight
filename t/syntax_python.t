package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Python;
use Test2::V0 -target => {
    SYNTAX_FILTER	=> 'App::AckX::Preflight::Syntax::Python' };

use lib qw{ inc };
use My::Module::TestSyntax;

use constant PYTHON_FILE	=> 't/data/python_file.py';

=begin comment

   1: #!/usr/bin/env python
   2: # This is a single-line comment
   3:
   4: """
   5: This is a multi-line comment.
   6: """
   7: import sys
   8:
   9: def who():
  10:     """ This function determines who we are greeting """
  11:     if len( sys.argv ) > 1:
  12:         return sys.argv[1] + "!"
  13:     return "World!"
  14:
  15: print "Hello", who()
  16:
  17: # ex: set filetype=python textwidth=72 autoindent :

=end comment

=cut

use constant PYTHON_CODE	=> <<'EOD';
   3:
   7: import sys
   8:
   9: def who():
  11:     if len( sys.argv ) > 1:
  12:         return sys.argv[1] + "!"
  13:     return "World!"
  14:
  15: print "Hello", who()
  16:
EOD

use constant PYTHON_COMMENT	=> <<'EOD';
   2: # This is a single-line comment
   4: """
   5: This is a multi-line comment.
   6: """
  17: # ex: set filetype=python textwidth=72 autoindent :
EOD

use constant PYTHON_METADATA	=> <<'EOD';
   1: #!/usr/bin/env python
EOD

use constant PYTHON_DOC	=> <<'EOD';
  10:     """ This function determines who we are greeting """
EOD

use constant PYTHON_CODE_DOC => <<'EOD';
   3:
   7: import sys
   8:
   9: def who():
  10:     """ This function determines who we are greeting """
  11:     if len( sys.argv ) > 1:
  12:         return sys.argv[1] + "!"
  13:     return "World!"
  14:
  15: print "Hello", who()
  16:
EOD

setup_slurp(
    type	=> 'python',
    extension	=> 'py',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( PYTHON_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ python } ],
    sprintf '%s handles python', SYNTAX_FILTER;

setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( PYTHON_FILE ), PYTHON_CODE, 'Only code, reading directly';

is slurp( $resource ), PYTHON_CODE, 'Only code, reading resource';


setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( PYTHON_FILE ), PYTHON_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), PYTHON_COMMENT, 'Only comments, reading resource';


setup_syntax( syntax => [ SYNTAX_METADATA ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_METADATA;

is slurp( PYTHON_FILE ), PYTHON_METADATA, 'Only metadata, reading directly';

is slurp( $resource ), PYTHON_METADATA, 'Only metadata, reading resource';


setup_syntax( syntax => [ SYNTAX_DATA ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DATA;


setup_syntax( syntax => [ SYNTAX_DOCUMENTATION ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( PYTHON_FILE ), PYTHON_DOC, 'Only documentation, reading directly';

is slurp( $resource ), PYTHON_DOC, 'Only documentation, reading resource';


setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_DOCUMENTATION ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

done_testing;

1;

# ex: set textwidth=72 :
