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
