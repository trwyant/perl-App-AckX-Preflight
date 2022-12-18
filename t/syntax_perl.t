package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Perl;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Scalar::Util qw{ blessed openhandle };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER	=> 'App::AckX::Preflight::Syntax::Perl';

use constant PERL_FILE	=> 't/data/perl_file.PL';

use constant PERL_CODE	=> <<'EOD';
   2:
   3: use strict;
   4: use warnings;
   5:
   6: printf "Hello %s!\n", @ARGV ? $ARGV[0] : 'world';
   7:
EOD

use constant PERL_METADATA	=> <<'EOD';
   1: #!/usr/bin/env perl
   8: __END__
EOD

use constant PERL_DATA	=> <<'EOD';
   9:
  10: This is data, kinda sorta.
  11:
  17:
  18: # ex: set textwidth=72 :
EOD

use constant PERL_DOC	=> <<'EOD';
  12: =head1 TEST
  13:
  14: This is documentation.
  15:
  16: =cut
EOD

use constant PERL_CODE_DOC => PERL_CODE . PERL_DOC;

$App::Ack::mappings{perl} = [
    App::Ack::Filter::Extension->new( qw{ PL } ),
];

my $perl_resource = ACK_FILE_CLASS->new( PERL_FILE );

my $text_resource = ACK_FILE_CLASS->new( TEXT_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ parrot perl perltest } ],
    sprintf '%s handles parrot, perl, perltest', SYNTAX_FILTER;

SYNTAX_FILTER->import( qw{ --syntax-add perlpod } );

is [ SYNTAX_FILTER->__handles_type() ],
    [ qw{ parrot perl perltest perlpod } ],
    sprintf 'Added perlpod to %s', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( PERL_FILE ), PERL_CODE, 'Only code, reading directly';

is slurp( $perl_resource ), PERL_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_METADATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_METADATA;

is slurp( PERL_FILE ), PERL_METADATA, 'Only metadata, reading directly';

is slurp( $perl_resource ), PERL_METADATA, 'Only metadata, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only metadata, text resource';

SYNTAX_FILTER->import( '--syntax', SYNTAX_DATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DATA;

is slurp( PERL_FILE ), PERL_DATA, 'Only data, reading directly';

is slurp( $perl_resource ), PERL_DATA, 'Only data, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only data, text resource';

SYNTAX_FILTER->import( '--syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( PERL_FILE ), PERL_DOC, 'Only documentation, reading directly';

is slurp( $perl_resource ), PERL_DOC, 'Only documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only documentation, text resource';

SYNTAX_FILTER->import( '--syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( PERL_FILE ), PERL_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $perl_resource ), PERL_CODE_DOC,
    'Code and documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and documentation, text resource';

note 'Test --syntax-empty-code-is-comment';

SYNTAX_FILTER->import( '--syntax', SYNTAX_CODE,
    '--syntax-empty-code-is-comment' );

is slurp( PERL_FILE ),
    <<'EOD', 'Code with --syntax-empty-code-is-comment';
   3: use strict;
   4: use warnings;
   6: printf "Hello %s!\n", @ARGV ? $ARGV[0] : 'world';
EOD

SYNTAX_FILTER->import( '--syntax', SYNTAX_COMMENT,
    '--syntax-empty-code-is-comment' );

is slurp( PERL_FILE ),
    <<'EOD', 'Comments with --syntax-empty-code-is-comment';
   2:
   5:
   7:
EOD

done_testing;

1;

# ex: set textwidth=72 :
