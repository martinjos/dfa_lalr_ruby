require 'tests/common.rb'
require 'lalr.rb'
require 'lalr_debug.rb'
require 'regexp_parser.rb'

($s, $all) = [RegexpLALRStart, RegexpLALRStates]
$allhash = {}
$all.each {|x| $allhash[x] = x}

def interned?(x)
    return $allhash[x] .equal? x
end
