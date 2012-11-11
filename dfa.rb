require 'set'

def regexp(reg)
    return reg.call(0)
end

# may lead to loops in blank transition graph...(as may opt and star)
def nothing
    return lambda do |pos|
        return []
    end
end

def range(first, last)
    return lambda do |pos|
        state = {}
        (first.ord..last.ord).map(&:chr).each do |ch|
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
        startstate = { '' => Set.new }
        statelist = [startstate]
        endstate = { '' => Set.new }
        curpos = pos + statelist.size
        list.each do |item|
            startstate[''] << curpos
            statelist += item.call(curpos)
            statelist << endstate
            curpos = pos + statelist.size
        end
        endstate[''] << curpos
        return statelist
    end
end

# used in the composition of star(reg)
def plus(reg)
    return lambda do |pos|
        statelist = reg.call(pos)
        curpos = pos + statelist.size
        endstate = { '' => Set.new( [pos, curpos + 1] ) }
        statelist << endstate
        return statelist
    end
end

# a bit more sparing of states than alt(reg, nothing)
def opt(reg)
    return lambda do |pos|
        startstate = { '' => Set.new( [pos + 1] ) }

        statelist = [startstate]
        curpos = pos + statelist.size

        statelist += reg.call(curpos)
        curpos = pos + statelist.size

        startstate[''] << curpos

        return statelist
    end
end

# AFAIK star effectively has to be implemented this way anyway
# This does end up with effectively a redundant state. However,
# AFAICT there is no way to change this without changing the
# way that the regexp is constructed.
# It will all be cleaned up anyway in conversion to a DFA (or
# one of the preliminary steps).
def star(reg)
    return opt(plus(reg))
end

def success(sym)
    return lambda do |pos|
        return [ { 'SUCCESS' => Set.new( [sym] ) } ]
    end
end

def show_nfa(nfa)
    nfa.each_with_index do |x,i|
        puts "#{i}: #{x}"
    end
    return nil
end

def show_dfa(dfa)
    dfa.each do |i, x|
        # for some reason Set overrides "inspect" instead of to_s...
        puts "#{i.inspect}: #{x}"
    end
    return nil
end

def make_dfa(nfa)

    # blank transitions are unnecessary. get rid of them.
    eliminate_blanks(nfa)

    # possibly canonicalise NFA before building DFA?
    # (could reduce state explosion ?)

    dfa = {}
    initial_state = Set.new( [0] )

    build_dfa_rec(nfa, dfa, initial_state)

    canonicalise_dfa(dfa)
    
    return [dfa, initial_state]
end

def canonicalise_dfa(dfa)
    begin
        puts "Canonicalisation step"

        changed = false
        canonical_states = {}
        renaming = {}

        dfa.reject! do |key, value|
            if canonical_states.has_key? value
                renaming[key] = canonical_states[value]
                true # reject!
            else
                canonical_states[value] = key
                false # don't reject.
            end
        end

        # each value is a State object
        dfa.each do |key, value|
            value.lookup.each do |ch, other_state|
                if renaming.has_key? other_state
                    value.lookup[ch] = renaming[other_state]
                    changed = true
                end
            end
        end
    end while changed
end

class State
    attr :lookup, true
    attr :success, true
    def initialize
        self.lookup = {}
        self.success = Set.new
    end
    def to_s
        return "State { :lookup => #{lookup}, :success => #{success.inspect} }"
    end
    def hash
        # not sure whether to try to improve this
        return lookup.hash + success.hash
    end
    def eql?(other)
        return self.lookup == other.lookup &&
            self.success == other.success
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
        dfa[state].lookup[ch] = next_state
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
        puts "Blank elimination step"

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
