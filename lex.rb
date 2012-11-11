require 'set'

class LexError < StandardError
end

def lex(dfa, enum)
    start_state = Set.new( [0] )
    state = start_state
    str = ""
    pos = 1
    if !enum.respond_to?(:each) && enum.respond_to?(:chars)
        enum = enum.chars
    end
    # need to yield everything from enum, plus "" to finish off
    # (transition always fails, no "" transitions can survive compilation)
    p = proc do |ch|
        success = dfa[state].success
        next_state = dfa[state].lookup[ch]
        if next_state.nil?
            if success.empty?
                raise LexError, "position #{pos}"
            elsif success.size == 1
                yield success.first, str
            else
                yield success, str
            end
            str = ""
        else
            state = next_state
            str += ch
        end
        pos += 1
    end
    enum.each &p
    p.call("")
end
