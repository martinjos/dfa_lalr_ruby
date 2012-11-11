require 'set'

class LexError < StandardError
    def initialize(pos, len)
        if pos == len
            super("at EOF")
        else
            super("at position #{pos}")
        end
    end
end

def lex(dfa, duck)
    start_state = Set.new( [0] )
    state = start_state
    str = ""
    pos = 0
    last_success = nil
    last_str = nil
    last_pos = nil

    yield_success = proc do |su, s, p|
        if su.size == 1
            yield su.first, s, p
        else
            yield su, s, p
        end
        state = start_state
        str = ""
        last_success = nil # don't bother clearing last_str or last_pos
    end

    # will need to yield everything from duck, possibly
    # backtracking along the way, plus "" to finish off.
    # (no "" transitions can survive compilation)
    p = proc do |ch|
        puts "At position #{pos}"
        success = dfa[state].success
        if !success.empty?
            last_success = success
            last_str = str
            last_pos = pos
        end
        next_state = dfa[state].lookup[ch]
        if next_state.nil?
            if last_success.nil?
                if str.empty? && pos == duck.size && state == start_state
                    throw :done
                else
                    #puts "#{str} #{pos} #{duck.size} #{state.inspect} #{start_state.inspect}"
                    raise LexError.new(pos, duck.size)
                end
            else
                yield_success.call last_success, last_str, last_pos
                pos = last_pos
            end
        else
            state = next_state
            str += ch
            pos += 1
        end
    end

    size = duck.size
    catch :done do
        while true
            if pos < size
                p.call(duck[pos])
            else
                p.call("")
            end
        end
    end
end
