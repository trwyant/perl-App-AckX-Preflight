package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Java;
use App::AckX::Preflight::Util qw{ :syntax };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Java';

use constant JAVA_FILE	=> 't/data/java_file.java';

use constant JAVA_CODE	=> <<'EOD';
   1: import java.io.*;
   2: import java.util.*;
   3:
  10:
  11: public class java_file {
  12:
  19:
  20:     public static void main( String argv[] ) {
  21: 	String name = argv.length > 0 ? argv[0] : "World";
  22: 	System.out.println( "Hello, " + name + "|" );
  23:     }
  24:
  25: }
  26:
EOD

use constant JAVA_COMMENTS	=> <<'EOD';
  27: // ex: set textwidth=72 :
EOD

use constant JAVA_DOC	=> <<'EOD';
   4: /**
   5:  * Implement a greeting in Java
   6:  *
   7:  * @author	Thomas R. Wyant, III F<wyant at cpan dot org>
   8:  * @version	0.000_001
   9:  */
  13:     /**
  14:      * This method is the mainline. It prints a greeting to the name
  15:      * given as the first command-line argument, defaulting to "World".
  16:      *
  17:      * @param argv[]	String command line arguments.
  18:      */
EOD

use constant JAVA_CODE_DOC => <<'EOD';
   1: import java.io.*;
   2: import java.util.*;
   3:
   4: /**
   5:  * Implement a greeting in Java
   6:  *
   7:  * @author	Thomas R. Wyant, III F<wyant at cpan dot org>
   8:  * @version	0.000_001
   9:  */
  10:
  11: public class java_file {
  12:
  13:     /**
  14:      * This method is the mainline. It prints a greeting to the name
  15:      * given as the first command-line argument, defaulting to "World".
  16:      *
  17:      * @param argv[]	String command line arguments.
  18:      */
  19:
  20:     public static void main( String argv[] ) {
  21: 	String name = argv.length > 0 ? argv[0] : "World";
  22: 	System.out.println( "Hello, " + name + "|" );
  23:     }
  24:
  25: }
  26:
EOD

$App::Ack::mappings{java} = [
    App::Ack::Filter::Extension->new( qw{ java } ),
];

my $java_resource = App::Ack::Resource->new( JAVA_FILE );

my $text_resource = App::Ack::Resource->new( TEXT_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ java cpp csharp objc } ],
    sprintf '%s handles java, cpp, csharp, objc', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( JAVA_FILE ), JAVA_CODE, 'Only code, reading directly';

is slurp( $java_resource ), JAVA_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( JAVA_FILE ), JAVA_COMMENTS, 'Only comments, reading directly';

is slurp( $java_resource ), JAVA_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( JAVA_FILE ), JAVA_DOC, 'Only documentation, reading directly';

is slurp( $java_resource ), JAVA_DOC, 'Only documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only documentation, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( JAVA_FILE ), JAVA_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $java_resource ), JAVA_CODE_DOC,
    'Code and documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and documentation, text resource';

done_testing;

1;

# ex: set textwidth=72 :
