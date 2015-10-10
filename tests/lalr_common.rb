require_relative 'common'
require_relative '../lalr'
require_relative '../lalr_debug'
require_relative '../regexp_parser'

($s, $all) = [RegexpLALRStart, RegexpLALRStates]
$allhash = {}
$all.each {|x| $allhash[x] = x}

def interned?(x)
    return $allhash[x] .equal? x
end
