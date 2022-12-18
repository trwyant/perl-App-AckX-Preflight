package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Crystal;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Crystal';

use constant CRYSTAL_FILE	=> 't/data/crystal_file.cr';

use constant CRYSTAL_CODE	=> <<'EOD';
   2:
   4:
   7:
   9: if ARGV.size == 0
  10:     name = "world"
  11: else
  12:     name = "#{ARGV[0]}"
  13: end
  14:
  24: puts "Hello, #{name}!"
EOD

use constant CRYSTAL_COMMENTS	=> <<'EOD';
   3: # This is a comment. Ack's type system calls this language 'crystal'.
  15: # This is documentation because it precedes a language element,
  16: # but we have no way to determine this without buffering the file.
  17: # So at least in the short term we will mis-call this comment.
  18: # I suppose a full implementation would buffer comments until
  19: # we find a language element or a blank line, then back up $.
  20: # and feed the lines one at a time with the proper identification,
  21: # but that sounds fraught with opportunities to write bugs.
EOD

use constant CRYSTAL_METADATA => <<'EOD';
   1: #! /usr/bin/env crystal
   5: annotation MyAnnotation	# This is metadata
   6: end
   8: @[MyAmnotation("This is metadata too")]
  22: @[MyAnnotation(
  23:     "This is also an annotation")]
EOD

$App::Ack::mappings{crystal} = [
    App::Ack::Filter::Extension->new( qw{ cr } ),
];

my $crystal_resource = ACK_FILE_CLASS->new( CRYSTAL_FILE );

my $text_resource = ACK_FILE_CLASS->new( TEXT_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ crystal } ],
    sprintf '%s handles crysta;', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( CRYSTAL_FILE ), CRYSTAL_CODE, 'Only code, reading directly';

is slurp( $crystal_resource ), CRYSTAL_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( CRYSTAL_FILE ), CRYSTAL_COMMENTS, 'Only comments, reading directly';

is slurp( $crystal_resource ), CRYSTAL_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_METADATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_METADATA;

is slurp( CRYSTAL_FILE ), CRYSTAL_METADATA,
    'Metadata, reading directly';

is slurp( $crystal_resource ), CRYSTAL_METADATA,
    'Metadata, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and comments, text resource';

done_testing;

1;

# ex: set textwidth=72 :
