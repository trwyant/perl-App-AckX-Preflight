package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Cpp;
use App::AckX::Preflight::Util qw{ :syntax };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Cpp';

use constant JAVA_FILE	=> 't/data/java_file.java';

use constant JAVA_CODE	=> <<'EOD';
   2:
   3: import java.io.*;
   4: import java.util.*;
   5:
  12:
  13: public class java_file {
  14:
  21:
  22:     public static void main( String argv[] ) {
  23: 	String name = argv.length > 0 ? argv[0] : "World";
  24: 	System.out.println( "Hello, " + name + "|" );
  25:     }
  26:
  27: }
  28:
EOD

use constant JAVA_COMMENTS	=> <<'EOD';
   1: /* This is a single-line block comment. Just because. */
  29: // ex: set textwidth=72 :
EOD

use constant JAVA_DOC	=> <<'EOD';
   6: /**
   7:  * Implement a greeting in Java
   8:  *
   9:  * @author	Thomas R. Wyant, III F<wyant at cpan dot org>
  10:  * @version	0.000_001
  11:  */
  15:     /**
  16:      * This method is the mainline. It prints a greeting to the name
  17:      * given as the first command-line argument, defaulting to "World".
  18:      *
  19:      * @param argv[]	String command line arguments.
  20:      */
EOD

use constant JAVA_CODE_DOC => <<'EOD';
   2:
   3: import java.io.*;
   4: import java.util.*;
   5:
   6: /**
   7:  * Implement a greeting in Java
   8:  *
   9:  * @author	Thomas R. Wyant, III F<wyant at cpan dot org>
  10:  * @version	0.000_001
  11:  */
  12:
  13: public class java_file {
  14:
  15:     /**
  16:      * This method is the mainline. It prints a greeting to the name
  17:      * given as the first command-line argument, defaulting to "World".
  18:      *
  19:      * @param argv[]	String command line arguments.
  20:      */
  21:
  22:     public static void main( String argv[] ) {
  23: 	String name = argv.length > 0 ? argv[0] : "World";
  24: 	System.out.println( "Hello, " + name + "|" );
  25:     }
  26:
  27: }
  28:
EOD

$App::Ack::mappings{java} = [
    App::Ack::Filter::Extension->new( qw{ java } ),
];

my $resource = App::Ack::Resource->new( JAVA_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ actionscript cpp java objc } ],
    sprintf '%s handles actionscript, cpp, java, objc', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( JAVA_FILE ), JAVA_CODE, 'Only code, reading directly';

is slurp( $resource ), JAVA_CODE, 'Only code, reading resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( JAVA_FILE ), JAVA_COMMENTS, 'Only comments, reading directly';

is slurp( $resource ), JAVA_COMMENTS, 'Only comments, reading resource';

SYNTAX_FILTER->import( '-syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( JAVA_FILE ), JAVA_DOC, 'Only documentation, reading directly';

is slurp( $resource ), JAVA_DOC, 'Only documentation, reading resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( JAVA_FILE ), JAVA_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), JAVA_CODE_DOC,
    'Code and documentation, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
