require 'tests/common.rb'
require 'nfa.rb'
require 'dfa.rb'

# /(a|b)*abb/
$abb_nfa = regexp seq star(alt(one('a'), one('b'))), one('a'), one('b'), one('b'), success(:done)

$abb = make_dfa($abb_nfa)
