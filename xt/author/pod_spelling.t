package main;

use strict;
use warnings;

use Test2::Tools::LoadModule;

load_module_or_skip_all 'Test::Spelling';

add_stopwords( <DATA> );

all_pod_files_spelling_ok();

1;
__DATA__
ack
ackxp
ackxprc
ASCIIbetical
ASCIIbetically
Asm
declarator
del
env
Fortran
getopt
hh
hoc
hocery
Javadoc
Lua
merchantability
os
perlcore
preflight
raku
TODO
unabbreviated
Vimscript
VMS
wc
Wyant
yaml
