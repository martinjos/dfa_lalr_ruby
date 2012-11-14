#!/usr/bin/env ruby

load 'tests/lex_common.rb'
load 'tests/lalr_common.rb'

p = proc {|x,y,z| puts "#{x} - #{y} - #{z}"}
lex(RegexpDFA, "123|foo\\||b(a)r\\**", &p)
