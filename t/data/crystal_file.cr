#! /usr/bin/env crystal

# This is a comment. Ack's type system calls this language 'crystal'.

annotation MyAnnotation	# This is metadata
end

@[MyAnnotation("This is metadata too")]
if ARGV.size == 0
    name = "world"
else
    name = "#{ARGV[0]}"
end

# This is documentation because it precedes a language element.
@[MyAnnotation(
    "This is also an annotation")]
puts "Hello, #{name}!"
