package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::SQL;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::SQL';

use constant SQL_FILE	=> 't/data/sql_file.sql';

use constant JAVA_CODE	=> <<'EOD';
   2:
   3: select * from brewery where state = 'ME' order by name;
   4:
EOD

use constant SQL_COMMENTS	=> <<'EOD';
   1: -- Select all breweries in the state of Maine
   5: /*
   6:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   7:  *
   8:  * Copyright (C) 2018-2020 by Thomas R. Wyant, III
   9:  *
  10:  * This program is distributed in the hope that it will be useful, but
  11:  * without any warranty; without even the implied warranty of
  12:  * merchantability or fitness for a particular purpose.
  13:  *
  14:  * ex: set textwidth=72 :
  15:  */
EOD

use constant SQL_CODE_COMMENTS => <<'EOD';
   1: -- Select all breweries in the state of Maine
   2:
   3: select * from brewery where state = 'ME' order by name;
   4:
   5: /*
   6:  * Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   7:  *
   8:  * Copyright (C) 2018-2020 by Thomas R. Wyant, III
   9:  *
  10:  * This program is distributed in the hope that it will be useful, but
  11:  * without any warranty; without even the implied warranty of
  12:  * merchantability or fitness for a particular purpose.
  13:  *
  14:  * ex: set textwidth=72 :
  15:  */
EOD

$App::Ack::mappings{sql} = [
    App::Ack::Filter::Extension->new( qw{ sql } ),
];

my $java_resource = ACK_FILE_CLASS->new( SQL_FILE );

my $text_resource = ACK_FILE_CLASS->new( TEXT_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ sql } ],
    sprintf '%s handles sql', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( SQL_FILE ), JAVA_CODE, 'Only code, reading directly';

is slurp( $java_resource ), JAVA_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( SQL_FILE ), SQL_COMMENTS, 'Only comments, reading directly';

is slurp( $java_resource ), SQL_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is not everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( SQL_FILE ), SQL_CODE_COMMENTS,
    'Code and comments, reading directly';

is slurp( $java_resource ), SQL_CODE_COMMENTS,
    'Code and comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and comments, text resource';

done_testing;

1;

# ex: set textwidth=72 :
