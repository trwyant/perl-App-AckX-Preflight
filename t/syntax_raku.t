package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Raku;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Scalar::Util qw{ blessed openhandle };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER	=> 'App::AckX::Preflight::Syntax::Raku';

use constant RAKU_FILE	=> 't/data/raku_file.raku';

use constant RAKU_CODE	=> <<'EOD';
   2:
   3: use v6;
   4:
   6:
  10:
  16:
  18: sub MAIN( $name='world' ) {
  19:     say "Hello $name!";
  20: }
EOD

use constant RAKU_METADATA	=> <<'EOD';
   1: #! /usr/bin/env rakudo
EOD

=begin comment

# Until I figure this out, if at all.

use constant PERL_DATA	=> <<'EOD';
   9:
  10: This is data, kinda sorta.
  11:
  17:
  18: # ex: set textwidth=72 :
EOD

=end comment

=cut

use constant RAKU_DOC	=> <<'EOD';
  11: =begin pod
  12:
  13: This is documentation
  14:
  15: =end pod
  17: #| This is a single-line declarator block, and therefore documentation
  21: #=<
  22:     This is a multi-line declarator block, and also documentation
  23: >
EOD

use constant RAKU_CODE_DOC => <<'EOD';
   2:
   3: use v6;
   4:
   6:
  10:
  11: =begin pod
  12:
  13: This is documentation
  14:
  15: =end pod
  16:
  17: #| This is a single-line declarator block, and therefore documentation
  18: sub MAIN( $name='world' ) {
  19:     say "Hello $name!";
  20: }
  21: #=<
  22:     This is a multi-line declarator block, and also documentation
  23: >
EOD

$App::Ack::mappings{raku} = [
    App::Ack::Filter::Extension->new( qw{ raku } ),
];

my $perl_resource = ACK_FILE_CLASS->new( RAKU_FILE );

my $text_resource = ACK_FILE_CLASS->new( TEXT_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ raku } ],
    sprintf '%s handles raku', SYNTAX_FILTER;

SYNTAX_FILTER->import( qw{ --syntax-add rakutest } );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ raku rakutest } ],
    sprintf 'Added rakutest to %s', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( RAKU_FILE ), RAKU_CODE, 'Only code, reading directly';

is slurp( $perl_resource ), RAKU_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_METADATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_METADATA;

is slurp( RAKU_FILE ), RAKU_METADATA, 'Only metadata, reading directly';

is slurp( $perl_resource ), RAKU_METADATA, 'Only metadata, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only metadata, text resource';

SYNTAX_FILTER->import( '--syntax', SYNTAX_DATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DATA;

=begin comment

is slurp( RAKU_FILE ), PERL_DATA, 'Only data, reading directly';

is slurp( $perl_resource ), PERL_DATA, 'Only data, reading resource';

=end comment

=cut

is slurp( $text_resource ), TEXT_CONTENT, 'Only data, text resource';

SYNTAX_FILTER->import( '--syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( RAKU_FILE ), RAKU_DOC, 'Only documentation, reading directly';

is slurp( $perl_resource ), RAKU_DOC, 'Only documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only documentation, text resource';

SYNTAX_FILTER->import( '--syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( RAKU_FILE ), RAKU_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $perl_resource ), RAKU_CODE_DOC,
    'Code and documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and documentation, text resource';

note 'Test --syntax-empty-code-is-comment';

SYNTAX_FILTER->import( '--syntax', SYNTAX_CODE,
    '--syntax-empty-code-is-comment' );

is slurp( RAKU_FILE ),
    <<'EOD', 'Code with --syntax-empty-code-is-comment';
   3: use v6;
  18: sub MAIN( $name='world' ) {
  19:     say "Hello $name!";
  20: }
EOD

SYNTAX_FILTER->import( '--syntax', SYNTAX_COMMENT,
    '--syntax-empty-code-is-comment' );

is slurp( RAKU_FILE ),
    <<'EOD', 'Comments with --syntax-empty-code-is-comment';
   2:
   4:
   5: # This is a comment
   6:
   7: #`(
   8:   This is a block comment
   9:   )
  10:
  16:
  24: # But this is just a comment.
EOD

done_testing;

1;

# ex: set textwidth=72 :
