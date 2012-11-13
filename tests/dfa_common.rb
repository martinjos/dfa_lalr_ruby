load 'tests/common.rb'
load 'nfa.rb'
load 'dfa.rb'

# /(a|b)*abb/
$abb_nfa = regexp seq star(alt(one('a'), one('b'))), one('a'), one('b'), one('b'), success(:done)

$abb = make_dfa($abb_nfa)
