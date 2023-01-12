package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Batch;
use Test2::V0 -target => {
    SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Batch' };

use lib qw{ inc };
use My::Module::TestSyntax;

use constant BATCH_FILE	=> 't/data/batch_file.bat';

use constant BATCH_CODE	=> <<'EOD';
   1: @echo off
   5: set name=world
   6: if .%1.==.. goto greet
   7: set name=%1
   8: :greet
   9: echo Hello %name%!
EOD

use constant BATCH_COMMENTS	=> <<'EOD';
   2: rem This is a comment
   3: @REM so is this
   4: :: and, by a strange quirk of fate, so is this.
EOD

use constant BATCH_CODE_COMMENT => <<'EOD';
   1: @echo off
   2: rem This is a comment
   3: @REM so is this
   4: :: and, by a strange quirk of fate, so is this.
   5: set name=world
   6: if .%1.==.. goto greet
   7: set name=%1
   8: :greet
   9: echo Hello %name%!
EOD

setup_slurp(
    type	=> 'batch',
    extension	=> 'bat',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( BATCH_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ batch } ],
    sprintf '%s handles batch', SYNTAX_FILTER;

setup_syntax( syntax => [ SYNTAX_CODE ] );


ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( BATCH_FILE ), BATCH_CODE, 'Only code, reading directly';

is slurp( $resource ), BATCH_CODE, 'Only code, reading resource';

setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( BATCH_FILE ), BATCH_COMMENTS, 'Only comments, reading directly';

is slurp( $resource ), BATCH_COMMENTS, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_COMMENT ] );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT,
    SYNTAX_METADATA;

is slurp( BATCH_FILE ), BATCH_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $resource ), BATCH_CODE_COMMENT,
    'Code and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
