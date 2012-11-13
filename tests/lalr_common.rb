load 'tests/common.rb'
load 'lalr.rb'
load 'regexp_parser.rb'

($s, $all) = RegexpLALR.compile
$allhash = {}
$all.each {|x| $allhash[x] = x}

def interned?(x)
    return $allhash[x] .equal? x
end
