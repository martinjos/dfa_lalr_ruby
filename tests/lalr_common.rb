require 'tests/common.rb'
require 'lalr.rb'
require 'regexp_parser.rb'

($s, $all) = RegexpLALR.compile
$allhash = {}
$all.each {|x| $allhash[x] = x}

def interned?(x)
    return $allhash[x] .equal? x
end
