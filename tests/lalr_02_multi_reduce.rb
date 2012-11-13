#!/usr/bin/env ruby

load 'tests/lalr_common.rb'

# this state (about to reduce :ClassList => :ClassList, :ClassItem) should have 3 reduction table entries
s1 = $s.reduce_tab.values[0].next.shift_tab["["].reduce_tab.values[0].next.shift_tab[:char].reduce_tab.values[0].next
assert(s1.reduce_tab.size == 3)

safe
