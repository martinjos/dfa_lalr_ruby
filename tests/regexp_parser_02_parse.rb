require 'tests/regexp_parser_common'
require 'parse'
require 'stream'

str = "123|foo\\||b(a(b|c)d)r\\**"
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

#puts str
final_state = parser.debug
assert(final_state == [:_Start])
