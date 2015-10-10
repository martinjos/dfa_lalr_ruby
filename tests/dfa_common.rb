require_relative 'common'
require_relative '../nfa'
require_relative '../dfa'

# /(a|b)*abb/
$abb_nfa = regexp seq star(alt(one('a'), one('b'))), one('a'), one('b'), one('b'), success(:done)

$abb = make_dfa($abb_nfa)
