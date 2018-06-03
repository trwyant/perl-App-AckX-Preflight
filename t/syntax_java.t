package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Java;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Java';

use constant JAVA_FILE	=> 't/data/java_file.java';

use constant JAVA_CODE	=> <<'EOD';
   2:
   3: import java.io.*;
   4: import java.util.*;
   5:
   9:
  16:
  17: public class java_file {
  18:
  25:
  26:     public static void main( String argv[] ) {
  27:         String name = argv.length > 0 ? argv[0] : "world";
  28:         System.out.println( "Hello " + name + "|" );
  29:     }
  30:
  31: }
  32:
EOD

use constant JAVA_COMMENTS	=> <<'EOD';
   1: /* This is a single-line block comment. Just because. */
  33: // ex: set textwidth=72 :
EOD

use constant JAVA_DOC	=> <<'EOD';
  10: /**
  11:  * Implement a greeting in Java
  12:  *
  13:  * @author      Thomas R. Wyant, III F<wyant at cpan dot org>
  14:  * @version     0.000_001
  15:  */
  19:     /**
  20:      * This method is the mainline. It prints a greeting to the name
  21:      * given as the first command-line argument, defaulting to "world".
  22:      *
  23:      * @param argv[]    String command line arguments.
  24:      */
EOD

use constant JAVA_METADATA	=> <<'EOD';
   6: @Author(
   7:     name = "Tom Wyant"
   8: )
EOD

use constant JAVA_CODE_DOC => <<'EOD';
   2:
   3: import java.io.*;
   4: import java.util.*;
   5:
   9:
  10: /**
  11:  * Implement a greeting in Java
  12:  *
  13:  * @author      Thomas R. Wyant, III F<wyant at cpan dot org>
  14:  * @version     0.000_001
  15:  */
  16:
  17: public class java_file {
  18:
  19:     /**
  20:      * This method is the mainline. It prints a greeting to the name
  21:      * given as the first command-line argument, defaulting to "world".
  22:      *
  23:      * @param argv[]    String command line arguments.
  24:      */
  25:
  26:     public static void main( String argv[] ) {
  27:         String name = argv.length > 0 ? argv[0] : "world";
  28:         System.out.println( "Hello " + name + "|" );
  29:     }
  30:
  31: }
  32:
EOD

$App::Ack::mappings{java} = [
    App::Ack::Filter::Extension->new( qw{ java } ),
];

my $resource = ACK_FILE_CLASS->new( JAVA_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ groovy java } ],
    sprintf '%s handles groovy, java', SYNTAX_FILTER;


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


SYNTAX_FILTER->import( '-syntax', SYNTAX_METADATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_METADATA;

is slurp( JAVA_FILE ), JAVA_METADATA, 'Only metadata, reading directly';

is slurp( $resource ), JAVA_METADATA, 'Only metadata, reading resource';


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
