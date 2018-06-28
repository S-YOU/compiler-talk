#!/usr/bin/env ruby

require_relative 'lib/crystal'

content = File.read ARGV[0]
lex = Crystal::Lexer.new(content)

while (n = lex.next_token) && n.type != :EOF
  p [n.type, n.value]
end

# cat lex.rb
# ruby lex.rb samples/mandelbrot.rb | less
