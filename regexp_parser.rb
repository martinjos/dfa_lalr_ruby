# I know this is not really supporting "characters" yet, per se.
# Only bytes. Just a bit of a demo.

def simple_char(ch)
    return seq(one(ch), success(ch))
end

def simple_char_alts(str)
    return alt(*str.chars.map{|x| simple_char(x) })
end

def basic_char_class(str)
    return alt(*str.chars.map{|x| one(x) })
end

def basic_inv_char_class(str)
    ords = str.chars.map(&:ord).sort.uniq
    ords.unshift(-1)
    ords.push(256)
    return alt(*(0 ... ords.size-1).map { |i|
        range((ords[i]+1).chr, (ords[i+1]-1).chr)
    })
end

# of course, in some contexts, :char will be augmented by e.g. "-".
# this will be handled by the parser.
simple_chars = "|[]^()-"
unary_op_chars = "*+?"
special_chars = simple_chars + unary_op_chars + "\\"

# this currently demonstrates a problem with the DFA compiler, which requires that the outer
# structure be a sequence ending in a success node
reg_nfa = regexp seq(alt(simple_char_alts(simple_chars),
                         seq(basic_char_class(unary_op_chars), success(:unary_op)),
                         seq(basic_inv_char_class(special_chars), success(:char)),
                         seq(one("\\"), basic_char_class(special_chars), success(:char))), success(nil))


RegexpDFA = make_dfa(reg_nfa)

RegexpLALR = ParserDesc.new :Alt => {
    :Alt => [[:Seq],
             [:Alt, "|", :Seq]],
    :Seq => [[],
             [:Seq, :Atom]],
    :Atom => [[:char],
              ["[", :ClassList, "]"],
              ["[", "^", :ClassList, "]"],
              ["(", :Alt, ")"],
              [:Atom, :unary_op]],
    :ClassList => [[],
                   [:ClassList, :ClassItem]],
    :ClassItem => [[:char],
                   [:char, "-", :char]],
}
