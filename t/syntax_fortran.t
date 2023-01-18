package main;

use 5.010001;

use strict;
use warnings;

use App::AckX::Preflight::Syntax::Fortran;
use Test2::V0 -target => 'App::AckX::Preflight::Syntax::Fortran';
use constant SYNTAX_FILTER => CLASS;

use lib qw{ inc };
use My::Module::TestSyntax;

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
  14: C Copyright (C) 2018-2023 by Thomas R. Wyant, III
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
  14: C Copyright (C) 2018-2023 by Thomas R. Wyant, III
  15: C
  16: C This program is distributed in the hope that it will be useful, but
  17: C without any warranty; without even the implied warranty of
  18: C merchantability or fitness for a particular purpose.
  19:
  20: C ex: set textwidth=72 :
EOD

setup_slurp(
    type	=> 'fortran',
    extension	=> 'for',
    # encoding	=> 'utf-8',
);

my $resource = ACK_FILE_CLASS->new( FORTRAN_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ fortran } ],
    sprintf '%s handles fortran', SYNTAX_FILTER;

setup_syntax( syntax => [ SYNTAX_CODE ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( FORTRAN_FILE ), FORTRAN_CODE, 'Only code, reading directly';

is slurp( $resource ), FORTRAN_CODE, 'Only code, reading resource';

setup_syntax( syntax => [ SYNTAX_COMMENT ] );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( FORTRAN_FILE ), FORTRAN_COMMENT, 'Only comments, reading directly';

is slurp( $resource ), FORTRAN_COMMENT, 'Only comments, reading resource';

setup_syntax( syntax => [ SYNTAX_CODE, SYNTAX_COMMENT ] );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( FORTRAN_FILE ), FORTRAN_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $resource ), FORTRAN_CODE_COMMENT,
    'Code and comments, reading resource';

done_testing;

1;

# ex: set textwidth=72 :
