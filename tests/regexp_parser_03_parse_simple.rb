require 'tests/regexp_parser_common'
require 'parse'
require 'stream'

str = "foo"
lexer = Lexer.new(RegexpDFA, str)
stream = FunctionLookahead.new {
    token = lexer.next
    if token
	token[0]
    else
	nil
    end
}
parser = Parser.new(RegexpLALRStart, stream)

puts str
parser.debug
