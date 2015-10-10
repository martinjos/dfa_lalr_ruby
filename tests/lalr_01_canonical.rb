#!/usr/bin/env ruby

require_relative 'lalr_common'

def check_canonical(x, y)
    assert(x .equal? y)
    assert(interned?(x))
    assert(interned?(y))
end

# these states (about to reduce :Alt => :Seq) should be the same object
s1 = $s.re(0)
s2 = $s.re(0).sh(:char).re(0).re(2, $s)
check_canonical(s1, s2)
