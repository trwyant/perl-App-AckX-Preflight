package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::Syntax::Fortran;
use App::AckX::Preflight::Util qw{ :syntax };
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Fortran';

use constant FORTRAN_FILE	=> 't/data/fortran_file.for';

use constant FORTRAN_CODE	=> <<'EOD';
   1:         print 1000
   2: 1000    format ( " Hello world!" )
   3:         call exit()
   4:         end
   5:
  13:
EOD

use constant FORTRAN_COMMENT	=> <<'EOD';
   6: C Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   7: C
   8: C Copyright (C) 2018 by Thomas R. Wyant, III
   9: C
  10: C This program is distributed in the hope that it will be useful, but
  11: C without any warranty; without even the implied warranty of
  12: C merchantability or fitness for a particular purpose.
  14: C ex: set textwidth=72 :
EOD

use constant FORTRAN_CODE_COMMENT => <<'EOD';
   1:         print 1000
   2: 1000    format ( " Hello world!" )
   3:         call exit()
   4:         end
   5:
   6: C Author: Thomas R. Wyant, III F<wyant at cpan dot org>
   7: C
   8: C Copyright (C) 2018 by Thomas R. Wyant, III
   9: C
  10: C This program is distributed in the hope that it will be useful, but
  11: C without any warranty; without even the implied warranty of
  12: C merchantability or fitness for a particular purpose.
  13:
  14: C ex: set textwidth=72 :
EOD

$App::Ack::mappings{fortran} = [
    App::Ack::Filter::Extension->new( qw{ for } ),
];

my $shell_resource = App::Ack::Resource->new( FORTRAN_FILE );

is_deeply [ SYNTAX_FILTER->__handles_type() ], [ qw{ fortran } ],
    sprintf '%s handles fortran', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( FORTRAN_FILE ), FORTRAN_CODE, 'Only code, reading directly';

is slurp( $shell_resource ), FORTRAN_CODE, 'Only code, reading resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( FORTRAN_FILE ), FORTRAN_COMMENT, 'Only comments, reading directly';

is slurp( $shell_resource ), FORTRAN_COMMENT, 'Only comments, reading resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( FORTRAN_FILE ), FORTRAN_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $shell_resource ), FORTRAN_CODE_COMMENT,
    'Code and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
