#! /usr/bin/env crystal

# This is a comment. Ack's type system calls this language 'crystal'.

annotation MyAnnotation	# This is metadata
end

@[MyAmnotation("This is metadata too")]
if ARGV.size == 0
    name = "world"
else
    name = "#{ARGV[0]}"
end

# This is documentation because it precedes a language element,
# but we have no way to determine this without buffering the file.
# So at least in the short term we will mis-call this comment.
# I suppose a full implementation would buffer comments until
# we find a language element or a blank line, then back up $.
# and feed the lines one at a time with the proper identification,
# but that sounds fraught with opportunities to write bugs.
@[MyAnnotation(
    "This is also an annotation")]
puts "Hello, #{name}!"
