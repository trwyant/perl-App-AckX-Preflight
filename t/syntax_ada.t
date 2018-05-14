package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Ada;
use App::AckX::Preflight::Util qw{ :syntax };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Ada';

use constant ADA_FILE	=> 't/data/ada_file.adb';

use constant SHELL_CODE	=> <<'EOD';
   1: with Ada.Text_IO;               use Ada.Text_IO;
   2: with Ada.Command_Line;          use Ada.Command_Line;
   3: with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
   4:
   7:
   8: procedure ada_file is
   9: name : Unbounded_String := To_Unbounded_String( "World" );
  10: begin
  11:     if Argument_Count > 0
  12:     then
  13:         name := To_Unbounded_String( Argument( 1 ) );
  14:     end if;
  15:     Put_Line( "Hello " & To_String( name ) & "!" );
  16: end ada_file;
EOD

use constant ADA_COMMENT	=> <<'EOD';
   5: -- This is a comment
   6: -- I have more, but ...
EOD

use constant ADA_CODE_COMMENT => <<'EOD';
   1: with Ada.Text_IO;               use Ada.Text_IO;
   2: with Ada.Command_Line;          use Ada.Command_Line;
   3: with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
   4:
   5: -- This is a comment
   6: -- I have more, but ...
   7:
   8: procedure ada_file is
   9: name : Unbounded_String := To_Unbounded_String( "World" );
  10: begin
  11:     if Argument_Count > 0
  12:     then
  13:         name := To_Unbounded_String( Argument( 1 ) );
  14:     end if;
  15:     Put_Line( "Hello " & To_String( name ) & "!" );
  16: end ada_file;
EOD

$App::Ack::mappings{ada} = [
    App::Ack::Filter::Extension->new( qw{ adb } ),
];

my $shell_resource = App::Ack::Resource->new( ADA_FILE );

my $text_resource = App::Ack::Resource->new( TEXT_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ], [ qw{ ada } ],
    sprintf '%s handles ada', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( ADA_FILE ), SHELL_CODE, 'Only code, reading directly';

is slurp( $shell_resource ), SHELL_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( ADA_FILE ), ADA_COMMENT, 'Only comments, reading directly';

is slurp( $shell_resource ), ADA_COMMENT, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( ADA_FILE ), ADA_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $shell_resource ), ADA_CODE_COMMENT,
    'Code and comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and comments, text resource';

done_testing;

1;

# ex: set textwidth=72 :
