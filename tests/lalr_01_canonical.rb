#!/usr/bin/env ruby

load 'tests/lalr_common.rb'

def check_canonical(x, y)
    assert(x .equal? y)
    assert(interned?(x))
    assert(interned?(y))
end

# these states (about to reduce :Alt => :Seq) should be the same object
s1 = $s.reduce_tab.values[0].next
s2 = $s.reduce_tab.values[0].next.shift_tab[:char].reduce_tab.values[0].next.reduce_tab.values[0].next
check_canonical(s1, s2)

safe
