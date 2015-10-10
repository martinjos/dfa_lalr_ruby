#!/usr/bin/env ruby

require_relative 'regexp_parser_common'
require_relative '../parse'
require_relative '../stream'

str = "(|)"
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
