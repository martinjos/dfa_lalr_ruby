require 'set'

# should probably derive from these at some point, and convert everything in
# the tree - either when flattening, or else at initialization

class Symbol
    # terminals - dromeDary camelCase or lower_case
    # I actually prefer to use lower_case for this, but I only
    # check the first character to leave dromeDary as an option.
    def terminal?
        self[0] == self[0].downcase
    end

    # labels - BLOCK_CAPS
    def label?
        self == self.upcase
    end

    # non-terminals - Bactrian CamelCase
    # Made this strictly Bactrian - I think it's important that non-terminals
    # should be distinguishable from labels.
    def non_terminal?
        self[0] == self[0].upcase && self != self.upcase
    end
end

class String
    def terminal?
        true
    end
    def label?
        false
    end
    def non_terminal?
        false
    end
end

class LalrCompileError < StandardError
end

class Rule
    attr :nterm, true
    attr :exp, true
    def initialize(nterm, exp)
        @nterm = nterm
        @exp = exp
    end
    def to_s
        return "Rule(nterm=#{nterm}, exp=#{exp})"
    end
end

class RuleState
    attr :rule, true
    attr :pos, true
    def nterm
        return rule.nterm
    end
    def exp
        return rule.exp
    end
    def initialize(rule, pos)
        @rule = rule
        @pos = pos
        raise StandardError if rule.nil?
    end
    def hash
        # good way to do this?
        return @rule.hash + @pos.hash
    end
    def eql? other
        return self.rule == other.rule &&
            self.pos == other.pos
    end
    def to_s
        return "RuleState(nterm=#{nterm}, exp=#{exp}, pos=#{pos})"
    end
end

class ParserState < Set
    def complete(fdesc)
        list = self.to_a
        while rs = list.shift
            if rs.pos < rs.exp.size
                nextsym = rs.exp[rs.pos]
                if fdesc.has_key? nextsym
                    # already checked that these are Bactrian
                    fdesc[nextsym].each do |rule|
                        nrs = RuleState.new(rule, 0)
                        if !self.include? nrs
                            list << nrs
                            self << nrs
                        end
                    end
                else
                    if !nextsym.terminal?
                        raise LalrCompileError.new("Terminal symbol #{nextsym} should be in lower_case")
                    end
                end
            end
        end
    end

    # can_shift? and num_reductions:
    # may want to cache the results at some point
    
    def can_shift?
        self.each do |rulestate|
            return true if rulestate.pos < rulestate.exp.size &&
                rulestate.exp[rulestate.pos].terminal?
        end
        return false
    end

    def num_reductions
        num = 0
        self.each do |rulestate|
            num += rulestate.pos == rulestate.exp.size ? 1 : 0
        end
        return num
    end

    def reductions
        return self.select do |rulestate|
            rulestate.pos == rulestate.exp.size
        end
    end

    def shift_keys
        keys = Set.new
        self.each do |rulestate|
            if rulestate.pos < rulestate.exp.size &&
                    rulestate.exp[rulestate.pos].terminal?
                keys << rulestate.exp[rulestate.pos]
            end
        end
        return keys
    end

    def shift(fdesc, key)
        new_state = ParserState.new
        self.each do |rulestate|
            if rulestate.pos < rulestate.exp.size &&
                    rulestate.exp[rulestate.pos] == key
                new_rulestate = RuleState.new(rulestate.rule, rulestate.pos + 1)
                new_state.add new_rulestate
            end
        end
        new_state.complete(fdesc)
        return new_state
    end

    def reduce(fdesc)
        r = reductions
        raise LalrCompileError, "Cannot reduce" if r.size == 0
        raise LalrCompileError, "Reduce-reduce conflict" if r.size > 1
        r = r[0]
        return shift(fdesc, r.nterm) # hehe! shift == reduce! all connected is, little one...
    end
end

class ParserDesc < Hash
    def initialize(hash)
        if hash.size != 1
            raise LalrCompileError, "Usage: ParserDesc.new :StartSymbol => { <parser-description> }"
        end
        @start_symbol = hash.keys[0]
        self.merge! hash[@start_symbol]
    end
    
    # in effect, this is just augmenting each (sub-)rule with its nonterminal...
    # I may rethink this at some point
    def flatten
        flat_desc = ParserDesc.new(@start_symbol => { :_Start => [Rule.new(:_Start, [@start_symbol])] })
        self.each do |nonterminal, expansions|
            if !nonterminal.non_terminal?
                raise LalrCompileError, "Non-terminal symbol #{nonterminal} should be in CamelCase (Bactrian, not dromeDary)"
            end
            expansions.each do |exp|
                if !flat_desc.has_key? nonterminal
                    flat_desc[nonterminal] = []
                end
                flat_desc[nonterminal] << Rule.new(nonterminal, exp)
            end
        end
        return flat_desc
    end

    def compile
        if self.has_key? :_Start
            raise LalrCompileError, "LALR description already contains :_Start token (used internally)"
        end
        fdesc = self.flatten
        start_rule = fdesc[:_Start][0]
        start_state = ParserState.new( [RuleState.new(start_rule, 0)] )
        start_state.complete(fdesc)
        return start_state
    end
end
