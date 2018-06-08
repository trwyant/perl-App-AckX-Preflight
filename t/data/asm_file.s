	.section __TEXT, __cstring

tplt:	.asciz	"Hello %s!\n"
world:	.asciz	"world"

	.section __TEXT, __text

# Hello world program. If an argument is given it is used instead of
# "world".
# In an attempt to make this portable, it is linked against the C
# runtime. Under macOS (as they spell it these days) the build is
# as asm_file.s -o asm_file.o
# ld -lc -o asm_file asm_file.o /usr/lib/crt1.o

	.globl	_main

_main:
	pushq	%rbp				# Save the base register
	movq	%rsp, %rbp			# Make the stack the base
	# Normally we would allocate space on the stack here, but we
	# do not need any.

	cmpl	$1, %edi			# Compare argc to 1
	jle	use_default			# If le, use default

	movq	%rsi, %rax			# Pick up argv
	movq	8(%rax), %rax			# Pick up argv[1]
	jmp	do_print			# Do the print

use_default:
	leaq	world(%rip), %rax		# Load default arg

do_print:
	leaq	tplt(%rip), %rdi		# Load template
	movq	%rax, %rsi
	movb	$0, %al
	callq	_printf				# printf()

	movl	$0, %edi			# Exit status
	callq	_exit				# Terminate program

# ex: set textwidth=72 autoindent :
