package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::YAML;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::YAML';

use constant DATA_FILE	=> 't/data/yaml_file.yml';

use constant DATA_DATA	=> <<'EOD';
   3: - There was a young lady named Bright,
   4: - Who could travel much faster than light.
   5: - '    She set out one day'
   6: - '    In a relative way'
   7: - And returned the previous night.
EOD

use constant DATA_COMMENT	=> <<'EOD';
   2: # This is a comment
EOD

use constant DATA_DATA_COMMENT_META => <<'EOD';
   1: ---
   2: # This is a comment
   3: - There was a young lady named Bright,
   4: - Who could travel much faster than light.
   5: - '    She set out one day'
   6: - '    In a relative way'
   7: - And returned the previous night.
EOD

$App::Ack::mappings{yaml} = [
    App::Ack::Filter::Extension->new( qw{ yml yaml } ),
];

my $resource = ACK_FILE_CLASS->new( DATA_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ yaml } ],
    sprintf '%s handles yaml', SYNTAX_FILTER;


SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_DATA );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_DATA;

is slurp( DATA_FILE ), DATA_DATA, 'Only data, reading directly';

is slurp( $resource ), DATA_DATA, 'Only data, reading resource';


SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( DATA_FILE ), DATA_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), DATA_COMMENT, 'Only comments, reading resource';


SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_DATA, SYNTAX_COMMENT,
    SYNTAX_METADATA );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s:%s' is everything>, SYNTAX_DATA, SYNTAX_COMMENT,
    SYNTAX_METADATA;

is slurp( DATA_FILE ), DATA_DATA_COMMENT_META,
    'Data, comments, and metadata, reading directly';

is slurp( $resource ), DATA_DATA_COMMENT_META,
    'Data, comments, and metadata, reading resource';


done_testing;

1;

# ex: set textwidth=72 :
