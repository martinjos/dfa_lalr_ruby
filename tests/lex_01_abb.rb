#!/usr/bin/env ruby

require 'tests/lex_common.rb'

str1 = "aaabbbbbabb"
tokens = []
lex($abb, str1) do |token, str|
    tokens << [token, str]
end
assert(tokens == [[:done, str1]])

str2 = str1 + "aaaba"
tokens = []
errors = []
begin
    lex($abb, str2) do |token, str|
        tokens << [token, str]
    end
rescue LexError => e
    errors << e.message
end
assert(tokens == [[:done, str1]])
assert(errors == ["at EOF"] || (puts(errors) && false))

safe
