package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Shell;
use App::AckX::Preflight::Util qw{ :syntax };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Shell';

use constant SHELL_FILE	=> 't/data/shell_file.sh';

use constant SHELL_CODE	=> <<'EOD';
   2:
   3: x=$1
   4: echo "Hello, ${x:-world}!"
   5:
  13:
EOD

use constant SHELL_COMMENTS	=> <<'EOD';
   1: #!/bin/sh
   6: # Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   7: #
   8: # Copyright (C) 2018 by Thomas R. Wyant, III
   9: #
  10: # This program is distributed in the hope that it will be useful, but
  11: # without any warranty; without even the implied warranty of
  12: # merchantability or fitness for a particular purpose.
  14: # ex: set textwidth=72 :
EOD

use constant SHELL_CODE_COMMENT => <<'EOD';
   1: #!/bin/sh
   2:
   3: x=$1
   4: echo "Hello, ${x:-world}!"
   5:
   6: # Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   7: #
   8: # Copyright (C) 2018 by Thomas R. Wyant, III
   9: #
  10: # This program is distributed in the hope that it will be useful, but
  11: # without any warranty; without even the implied warranty of
  12: # merchantability or fitness for a particular purpose.
  13:
  14: # ex: set textwidth=72 :
EOD

$App::Ack::mappings{shell} = [
    App::Ack::Filter::Extension->new( qw{ sh } ),
];

my $shell_resource = App::Ack::Resource->new( SHELL_FILE );

my $text_resource = App::Ack::Resource->new( TEXT_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ], [ qw{ python shell } ],
    sprintf '%s handles python, shell', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( SHELL_FILE ), SHELL_CODE, 'Only code, reading directly';

is slurp( $shell_resource ), SHELL_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( SHELL_FILE ), SHELL_COMMENTS, 'Only comments, reading directly';

is slurp( $shell_resource ), SHELL_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( SHELL_FILE ), SHELL_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $shell_resource ), SHELL_CODE_COMMENT,
    'Code and comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and comments, text resource';

done_testing;

1;

# ex: set textwidth=72 :
