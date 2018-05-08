package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Perl;
use App::AckX::Preflight::Util qw{ :syntax };
use Scalar::Util qw{ blessed openhandle };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER	=> 'App::AckX::Preflight::Syntax::Perl';
use constant PERL_FILE	=> 't/data/perl_file.PL';

use constant PERL_CODE	=> <<'EOD';
   2:
   3: use strict;
   4: use warnings;
   5:
EOD

use constant PERL_COMMENTS	=> <<'EOD';
   1: #!/usr/bin/env perl
EOD

use constant PERL_DATA	=> <<'EOD';
   6: __END__
   7:
   8: This is data, kinda sorta.
   9:
EOD

use constant PERL_DOC	=> <<'EOD';
  10: =head1 TEST
  11:
  12: This is a test. It is only a test.
  13:
  14: =cut
EOD

use constant PERL_CODE_DOC => PERL_CODE . PERL_DOC;

$App::Ack::mappings{perl} = [
    App::Ack::Filter::Extension->new( qw{ PL } ),
];

my $perl_resource = App::Ack::Resource->new( PERL_FILE );

my $text_resource = App::Ack::Resource->new( TEXT_FILE );

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( PERL_FILE ), PERL_CODE, 'Only code, reading directly';

is slurp( $perl_resource ), PERL_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( PERL_FILE ), PERL_COMMENTS, 'Only comments, reading directly';

is slurp( $perl_resource ), PERL_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', SYNTAX_DATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DATA;

is slurp( PERL_FILE ), PERL_DATA, 'Only data, reading directly';

is slurp( $perl_resource ), PERL_DATA, 'Only data, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only data, text resource';

SYNTAX_FILTER->import( '-syntax', SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DOCUMENTATION;

is slurp( PERL_FILE ), PERL_DOC, 'Only documentation, reading directly';

is slurp( $perl_resource ), PERL_DOC, 'Only documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only documentation, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_DOCUMENTATION );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_DOCUMENTATION;

is slurp( PERL_FILE ), PERL_CODE_DOC,
    'Code and documentation, reading directly';

is slurp( $perl_resource ), PERL_CODE_DOC,
    'Code and documentation, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and documentation, text resource';

done_testing;

1;

# ex: set textwidth=72 :
