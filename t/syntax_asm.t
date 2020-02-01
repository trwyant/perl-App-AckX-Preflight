package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::AckX::Preflight::Syntax::Asm;
use App::AckX::Preflight::Util qw{ :syntax ACK_FILE_CLASS };
use Test2::V0;

use lib qw{ inc };
use My::Module::TestSyntax;	# for slurp() and TEXT_*

use constant SYNTAX_FILTER => 'App::AckX::Preflight::Syntax::Asm';

use constant ASM_FILE	=> 't/data/asm_file.s';

use constant ASM_CODE	=> <<'EOD';
   1: 	.section __TEXT, __cstring
   2:
   3: tplt:	.asciz	"Hello %s!\n"
   4: world:	.asciz	"world"
   5:
   6: 	.section __TEXT, __text
   7:
  14:
  15: 	.globl	_main
  16:
  17: _main:
  18: 	pushq	%rbp				# Save the base register
  19: 	movq	%rsp, %rbp			# Make the stack the base
  22:
  23: 	cmpl	$1, %edi			# Compare argc to 1
  24: 	jle	use_default			# If le, use default
  25:
  26: 	movq	%rsi, %rax			# Pick up argv
  27: 	movq	8(%rax), %rax			# Pick up argv[1]
  28: 	jmp	do_print			# Do the print
  29:
  30: use_default:
  31: 	leaq	world(%rip), %rax		# Load default arg
  32:
  33: do_print:
  34: 	leaq	tplt(%rip), %rdi		# Load template
  35: 	movq	%rax, %rsi
  36: 	movb	$0, %al
  37: 	callq	_printf				# printf()
  38:
  39: 	movl	$0, %edi			# Exit status
  40: 	callq	_exit				# Terminate program
  41:
EOD

use constant ASM_COMMENTS	=> <<'EOD';
   8: # Hello world program. If an argument is given it is used instead of
   9: # "world".
  10: # In an attempt to make this portable, it is linked against the C
  11: # runtime. Under macOS (as they spell it these days) the build is
  12: # as asm_file.s -o asm_file.o
  13: # ld -lc -o asm_file asm_file.o /usr/lib/crt1.o
  20: 	# Normally we would allocate space on the stack here, but we
  21: 	# do not need any.
  42: # ex: set textwidth=72 autoindent :
EOD

use constant ASM_CODE_COMMENT => <<'EOD';
   1: 	.section __TEXT, __cstring
   2:
   3: tplt:	.asciz	"Hello %s!\n"
   4: world:	.asciz	"world"
   5:
   6: 	.section __TEXT, __text
   7:
   8: # Hello world program. If an argument is given it is used instead of
   9: # "world".
  10: # In an attempt to make this portable, it is linked against the C
  11: # runtime. Under macOS (as they spell it these days) the build is
  12: # as asm_file.s -o asm_file.o
  13: # ld -lc -o asm_file asm_file.o /usr/lib/crt1.o
  14:
  15: 	.globl	_main
  16:
  17: _main:
  18: 	pushq	%rbp				# Save the base register
  19: 	movq	%rsp, %rbp			# Make the stack the base
  20: 	# Normally we would allocate space on the stack here, but we
  21: 	# do not need any.
  22:
  23: 	cmpl	$1, %edi			# Compare argc to 1
  24: 	jle	use_default			# If le, use default
  25:
  26: 	movq	%rsi, %rax			# Pick up argv
  27: 	movq	8(%rax), %rax			# Pick up argv[1]
  28: 	jmp	do_print			# Do the print
  29:
  30: use_default:
  31: 	leaq	world(%rip), %rax		# Load default arg
  32:
  33: do_print:
  34: 	leaq	tplt(%rip), %rdi		# Load template
  35: 	movq	%rax, %rsi
  36: 	movb	$0, %al
  37: 	callq	_printf				# printf()
  38:
  39: 	movl	$0, %edi			# Exit status
  40: 	callq	_exit				# Terminate program
  41:
  42: # ex: set textwidth=72 autoindent :
EOD

$App::Ack::mappings{asm} = [
    App::Ack::Filter::Extension->new( qw{ s } ),
];

my $shell_resource = ACK_FILE_CLASS->new( ASM_FILE );

my $text_resource = ACK_FILE_CLASS->new( TEXT_FILE );

is [ SYNTAX_FILTER->__handles_type() ], [ qw{ asm } ],
    sprintf '%s handles asm', SYNTAX_FILTER;

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_CODE );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_CODE;

is slurp( ASM_FILE ), ASM_CODE, 'Only code, reading directly';

is slurp( $shell_resource ), ASM_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

SYNTAX_FILTER->import( sprintf '-syntax=%s', SYNTAX_COMMENT );

ok ! SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s' is not everything>, SYNTAX_COMMENT;

is slurp( ASM_FILE ), ASM_COMMENTS, 'Only comments, reading directly';

is slurp( $shell_resource ), ASM_COMMENTS, 'Only comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only comments, text resource';

SYNTAX_FILTER->import( '-syntax', join ':', SYNTAX_CODE, SYNTAX_COMMENT,
    SYNTAX_METADATA );

ok SYNTAX_FILTER->__want_everything(),
    sprintf q<'%s:%s' is everything>, SYNTAX_CODE, SYNTAX_COMMENT;

is slurp( ASM_FILE ), ASM_CODE_COMMENT,
    'Code and comments, reading directly';

is slurp( $shell_resource ), ASM_CODE_COMMENT,
    'Code and comments, reading resource';

is slurp( $text_resource ), TEXT_CONTENT,
    'Code and comments, text resource';

done_testing;

1;

# ex: set textwidth=72 :
