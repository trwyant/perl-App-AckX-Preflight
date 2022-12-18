package main;

use 5.010001;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Fortran;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Fortran';

use constant FORTRAN_FILE	=> 't/data/fortran_file.for';

use constant FORTRAN_CODE	=> <<'EOD';
   1:       character*64 my_name
   2:       if ( iargc() .gt. 0 ) then
   3:           call getarg( 1, my_name )
   4:       else
   5:           my_name = "world"
   6:       end if
   7:       print 1000, trim( my_name )
   8: 1000  format ( "Hello ", A, "!" )
   9:       call exit()
  10:       end
  11:
  19:
EOD

use constant FORTRAN_COMMENT	=> <<'EOD';
  12: C Author: Thomas R. Wyant, III F<wyant at cpan dot org>
  13: C
  14: C Copyright (C) 2018-2022 by Thomas R. Wyant, III
  15: C
  16: C This program is distributed in the hope that it will be useful, but
  17: C without any warranty; without even the implied warranty of
  18: C merchantability or fitness for a particular purpose.
  20: C ex: set textwidth=72 :
EOD

use constant FORTRAN_CODE_COMMENT => <<'EOD';
   1:       character*64 my_name
   2:       if ( iargc() .gt. 0 ) then
   3:           call getarg( 1, my_name )
   4:       else
   5:           my_name = "world"
   6:       end if
   7:       print 1000, trim( my_name )
   8: 1000  format ( "Hello ", A, "!" )
   9:       call exit()
  10:       end
  11:
  12: C Author: Thomas R. Wyant, III F<wyant at cpan dot org>
  13: C
  14: C Copyright (C) 2018-2022 by Thomas R. Wyant, III
  15: C
  16: C This program is distributed in the hope that it will be useful, but
  17: C without any warranty; without even the implied warranty of
  18: C merchantability or fitness for a particular purpose.
  19:
  20: C ex: set textwidth=72 :
EOD

$App::Ack::mappings{fortran} = [
    App::Ack::Filter::Extension->new( qw{ for } ),
];

my $shell_resource = ACK_FILE_CLASS->new( FORTRAN_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ fortran } ],
    sprintf '%s handles fortran', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( FORTRAN_FILE ), FORTRAN_CODE, 'Only code, reading directly';

is slurp( $shell_resource ), FORTRAN_CODE, 'Only code, reading resource';

SYNTAX_FILTER->import( sprintf '--syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( FORTRAN_FILE ), FORTRAN_COMMENT, 'Only comments, reading directly';

is slurp( $shell_resource ), FORTRAN_COMMENT, 'Only comments, reading resource';

SYNTAX_FILTER->import( '--syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( FORTRAN_FILE ), FORTRAN_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $shell_resource ), FORTRAN_CODE_COMMENT,
    'Code and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
