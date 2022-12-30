package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Swift;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Swift';

use constant SWIFT_FILE	=> 't/data/swift_file.swift';

use constant SWIFT_CODE	=> <<'EOD';
   2:
   7:
  14:
  16: let name = CommandLine.argc > 1 ? CommandLine.arguments[ 1 ] : "world"
  17:
  18: print( "Hello " + name + "!" )
EOD

use constant SWIFT_COMMENT	=> <<'EOD';
   3: /* This is a block comment.
   4:  * /* Note that they nest, */
   5:  * so this is still a comment.
   6:  */
  15: // Note that the following makes 'name' a manifest constant.
EOD

use constant SWIFT_DOC	=> <<'EOD';
   8: /*:
   9:  * This is a Swift implementation of 'Hello world', which accepts an
  10:  * optional command line parameter specifying who to greet.
  11:  *
  12:  * The colon on the first line makes this documentation.
  13:  */
EOD

use constant SWIFT_CODE_COMMENT_DOC => <<'EOD';
   2:
   3: /* This is a block comment.
   4:  * /* Note that they nest, */
   5:  * so this is still a comment.
   6:  */
   7:
   8: /*:
   9:  * This is a Swift implementation of 'Hello world', which accepts an
  10:  * optional command line parameter specifying who to greet.
  11:  *
  12:  * The colon on the first line makes this documentation.
  13:  */
  14:
  15: // Note that the following makes 'name' a manifest constant.
  16: let name = CommandLine.argc > 1 ? CommandLine.arguments[ 1 ] : "world"
  17:
  18: print( "Hello " + name + "!" )
EOD

use constant SWIFT_META	=> <<'EOD';
   1: #!/usr/bin/env swift
EOD

$App::Ack::mappings{swift} = [
    App::Ack::Filter::Extension->new( qw{ swift } ),
];

my $resource = ACK_FILE_CLASS->new( SWIFT_FILE );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ swift } ],
    sprintf '%s handles swift', SYNTAX_FILTER;


setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( SWIFT_FILE ), SWIFT_CODE, 'Only code, reading directly';

is slurp( $resource ), SWIFT_CODE, 'Only code, reading resource';


setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( SWIFT_FILE ), SWIFT_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), SWIFT_COMMENT, 'Only comments, reading resource';


setup_syntax( syntax => [ SYNTAX_DOCUMENTATION ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( SWIFT_FILE ), SWIFT_DOC, 'Only documentation, reading directly';

is slurp( $resource ), SWIFT_DOC, 'Only documentation, reading resource';


setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_COMMENT,
	SYNTAX_DOCUMENTATION ] );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s:%s' is not everything>, SYNTAX_CODE,
    SYNTAX_COMMENT, SYNTAX_DOCUMENTATION;

is slurp( SWIFT_FILE ), SWIFT_CODE_COMMENT_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), SWIFT_CODE_COMMENT_DOC,
    'Code and documentation, reading resource';


setup_syntax( syntax => [ SYNTAX_METADATA ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_METADATA;

is slurp( SWIFT_FILE ), SWIFT_META, 'Only metadata, reading directly';

is slurp( $resource ), SWIFT_META, 'Only metadata, reading resource';


done_testing;

1;

# ex: set textwidth=72 :
