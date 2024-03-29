package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Data;
use Test2::V0 -target => 'App::AckX::Preflight::Syntax::Data';
use constant SYNTAX_FILTER => CLASS;

use lib qw{ inc };
use My::Module::TestSyntax;

use constant DATA_FILE	=> 't/data/json_file.json';

use constant DATA_DATA	=> <<'EOD';
   1: [
   2:     "There was a young lady named Bright,",
   3:     "Who could travel much faster than light.",
   4:     "    She set out one day",
   5:     "    In a relative way",
   6:     "And returned the previous night."
   7: ]
EOD

use constant DATA_COMMENT	=> undef;

use constant DATA_DATA_COMMENT => <<'EOD';
   1: [
   2:     "There was a young lady named Bright,",
   3:     "Who could travel much faster than light.",
   4:     "    She set out one day",
   5:     "    In a relative way",
   6:     "And returned the previous night."
   7: ]
EOD

setup_slurp(
    type	=> 'json',
    extension	=> 'json',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( DATA_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ json } ],
    sprintf '%s handles json', SYNTAX_FILTER;

### SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_DATA );
setup_syntax( syntax => [ SYNTAX_DATA ] );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is everything>, SYNTAX_DATA;

is slurp( DATA_FILE ), DATA_DATA, 'Only data, reading directly';

is slurp( $resource ), DATA_DATA, 'Only data, reading resource';

### SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_COMMENT );
setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( DATA_FILE ), DATA_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), DATA_COMMENT, 'Only comments, reading resource';

### SYNTAX_FILTER->import( '--syntax', join ':', SYNTAX_DATA, SYNTAX_COMMENT );
setup_syntax( syntax => [ SYNTAX_DATA, SYNTAX_COMMENT ] );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_DATA, SYNTAX_COMMENT;

is slurp( DATA_FILE ), DATA_DATA_COMMENT,
    'Data and comments, reading directly';

is slurp( $resource ), DATA_DATA_COMMENT,
    'Data and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
