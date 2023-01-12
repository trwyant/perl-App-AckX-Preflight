package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Vim;
use Test2::V0 -target => {
    SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Vim' };

use lib qw{ inc };
use My::Module::TestSyntax;

use constant VIM_FILE	=> 't/data/vim_file.vim';

use constant VIM_CODE	=> <<'EOD';
   2: let name = "world"
   3: echo "Hello " . name . "!"
EOD

use constant VIM_COMMENTS	=> <<'EOD';
   1: " This is a comment
EOD

use constant VIM_CODE_COMMENT => <<'EOD';
   1: " This is a comment
   2: let name = "world"
   3: echo "Hello " . name . "!"
EOD

setup_slurp(
    type	=> 'vim',
    extension	=> 'vim',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( VIM_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ vim } ],
    sprintf '%s handles vim', SYNTAX_FILTER;

setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( VIM_FILE ), VIM_CODE, 'Only code, reading directly';

is slurp( $resource ), VIM_CODE, 'Only code, reading resource';

setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( VIM_FILE ), VIM_COMMENTS, 'Only comments, reading directly';

is slurp( $resource ), VIM_COMMENTS, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_COMMENT ] );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( VIM_FILE ), VIM_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $resource ), VIM_CODE_COMMENT,
    'Code and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
