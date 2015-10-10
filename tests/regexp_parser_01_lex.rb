#!/usr/bin/env ruby

require_relative 'regexp_parser_common'

regexp = "123|foo\\||b(a)r\\**"
expect_tokens = [[:char, "1", 1], [:char, "2", 2], [:char, "3", 3], ["|", "|", 4], [:char, "f", 5], [:char, "o", 6], [:char, "o", 7], [:char, "\\|", 9], ["|", "|", 10], [:char, "b", 11], ["(", "(", 12], [:char, "a", 13], [")", ")", 14], [:char, "r", 15], [:char, "\\*", 17], [:unary_op, "*", 18]]
tokens = []
p = proc {|x,y,z| tokens << [x,y,z]}
lex(RegexpDFA, regexp, &p)
assert(tokens == expect_tokens)
#p tokens
