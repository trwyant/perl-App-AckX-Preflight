package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Lua;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Lua';

use constant LUA_FILE	=> 't/data/lua_file.lua';

use constant LUA_CODE	=> <<'EOD';
   2:
   4:
   7:
   9:
  13:
  17:
  18: if arg[1] == nil
  19:     then name = "world"
  20:     else name = arg[1]
  21:     end
  22: print( "Hello " .. name .. "!" );
EOD

use constant LUA_COMMENT	=> <<'EOD';
   3: -- this is a comment
   8: --[[ this is a block comment ]]
  10: --[==[
  11:   This is also a block comment
  12:   ]==]
EOD

use constant LUA_DOC	=> <<'EOD';
   5: --- But this is documentation
   6: -- and so is this, now.
  14: --[=[-
  15:   But this is documentation
  16:   ]=]
EOD

use constant LUA_CODE_DOC => <<'EOD';
   2:
   4:
   5: --- But this is documentation
   6: -- and so is this, now.
   7:
   9:
  13:
  14: --[=[-
  15:   But this is documentation
  16:   ]=]
  17:
  18: if arg[1] == nil
  19:     then name = "world"
  20:     else name = arg[1]
  21:     end
  22: print( "Hello " .. name .. "!" );
EOD

use constant LUA_METADATA	=> <<'EOD';
   1: #!/usr/bin/env lua
EOD

$App::Ack::mappings{lua} = [
    App::Ack::Filter::Extension->new( qw{ lua } ),
];

my $resource = ACK_FILE_CLASS->new( LUA_FILE );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ lua } ],
    sprintf '%s handles lua', SYNTAX_FILTER;


SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( LUA_FILE ), LUA_CODE, 'Only code, reading directly';

is slurp( $resource ), LUA_CODE, 'Only code, reading resource';


SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( LUA_FILE ), LUA_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), LUA_COMMENT, 'Only comments, reading resource';


SYNTAX_FILTER->import( '-syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( LUA_FILE ), LUA_DOC, 'Only documentation, reading directly';

is slurp( $resource ), LUA_DOC, 'Only documentation, reading resource';


SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok !SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( LUA_FILE ), LUA_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $resource ), LUA_CODE_DOC,
    'Code and documentation, reading resource';


SYNTAX_FILTER->import( '-syntax', SYNTAX_METADATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_METADATA;

is slurp( LUA_FILE ), LUA_METADATA, 'Only metadata, reading directly';

is slurp( $resource ), LUA_METADATA, 'Only metadata, reading resource';


done_testing;

1;

# ex: set textwidth=72 :
