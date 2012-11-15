#!/usr/bin/env ruby

require 'tests/regexp_parser_common.rb'

p = proc {|x,y,z| puts "#{x} - #{y} - #{z}"}
lex(RegexpDFA, "123|foo\\||b(a)r\\**", &p)
