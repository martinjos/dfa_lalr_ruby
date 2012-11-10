require 'set'

def range(first, last)
    return lambda do |pos|
        state = {}
        (first.ord..last.ord).map{|x| x.chr}.each do |ch|
            state[ch] = Set.new( [pos + 1] )
        end
        return [state]
    end
end

def one(ch)
    return range(ch, ch)
end

def any
    return range("\x00", "\xFF")
end

def seq(*list)
    return lambda do |pos|
        statelist = []
        curpos = pos
        list.each do |item|
            statelist += item.call(curpos)
            curpos = pos + statelist.size
        end
        return statelist
    end
end

# N.B. this assumes that the NFA will not be modified after creation
# (breaking this assumption will result in problems)
def alt(*list)
    return lambda do |pos|
        statelist = []
        endstate = { '' => Set.new }
        curpos = pos
        list.each do |item|
            statelist += item.call(curpos)
            statelist << endstate
            curpos = pos + statelist.size
        end
        endstate[''] << curpos
        return statelist
    end
end

def lots(reg)
    return lambda do |pos|
        statelist = reg.call(pos)
        curpos = pos + statelist.size
        endstate = { '' => Set.new( [pos, curpos + 1] ) }
        statelist << endstate
        return statelist
    end
end

def success(num)
    return lambda do |pos|
        return [ { 'SUCCESS' => Set.new( [num] ) } ]
    end
end

def make_dfa(nfa)

    # blank transitions are unnecessary. get rid of them.
    eliminate_blanks(nfa)

    dfa = {}
    initial_state = Set.new( [0] )

    build_dfa_rec(nfa, dfa, initial_state)
    
    return [dfa, initial_state]
end

class State
    attr :lookup, true
    attr :success, true
    def initialize
        self.lookup = {}
        self.success = Set.new
    end
    def to_s
        return "State { :lookup => #{lookup}, :success => #{success} }"
    end
end

def build_dfa_rec(nfa, dfa, state)
    return if dfa.has_key? state
    dfa[state] = State.new
    keys = get_dfa_keys(nfa, state)
    if keys.member? "SUCCESS"
        # my success shall live on...
        dfa[state].success = get_dfa_state(nfa, state, "SUCCESS")
        keys.delete "SUCCESS"
    end
    keys.each do |ch|
        next_state = get_dfa_state(nfa, state, ch)
        dfa[state].lookup[ch.ord] = next_state
        build_dfa_rec(nfa, dfa, next_state)
    end
end

def get_dfa_state(nfa, state, ch)
    new_state = Set.new
    state.each do |idx|
        if nfa[idx].has_key? ch
            new_state += nfa[idx][ch]
        end
    end
    return new_state
end

# N.B. this will return the SUCCESS key if applicable
def get_dfa_keys(nfa, state)
    # possibly eliminable inefficiency here
    keys = Set.new
    state.each do |idx|
        keys += nfa[idx].keys
    end
    return keys
end

def eliminate_blanks(nfa)
    with_blank = Set.new
    nfa.each_with_index do |state, idx|
        if state.has_key? ''
            with_blank << idx
        end
    end

    #puts "with_blank is #{with_blank}"

    # this should be okay with alt(), because
    # 1. if one of the end-states should change, the others should too
    # 2. when one of the end-states is done changing, the others will be too,
    #    and all will be removed in the normal course of things

    # (compiler) efficiency could probably be improved, by detecting when a state
    # can never change again (only really possible with trees, though, I think)

    # actually, I think it might work with loops as well, as progress is bound to
    # be stopped sooner or later when it runs out of new information.
    # (also the basis of the current halting guarantee, of course.)

    begin
        changed = false
        with_blank.each do |idx|
            nfa[idx][''].each do |idx2|
                #puts "idx2 is #{idx2}"
                nfa[idx2].each_key do |key|
                    # N.B. this works with SUCCESS keys as well as character ones
                    if !nfa[idx].has_key? key
                        nfa[idx][key] = Set.new
                    end
                    if !nfa[idx][key].superset? nfa[idx2][key]
                        nfa[idx][key] += nfa[idx2][key]
                        changed = true
                    end
                end
            end
        end
    end while changed

    with_blank.each do |idx|
        nfa[idx].delete('')
    end
end
