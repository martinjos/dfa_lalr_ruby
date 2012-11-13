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

    def initialize(desc, elems=[])
        @desc = desc
        @shift_tab = {}
        @reduce_tab = {}
        super(elems)
    end
    
    def complete
        list = self.to_a
        while rs = list.shift
            if rs.pos < rs.exp.size
                nextsym = rs.exp[rs.pos]
                if @desc.has_key? nextsym
                    # already checked that these are Bactrian
                    @desc[nextsym].each do |rule|
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

    def compile(all=Set.new, stack=[])
        self.complete
        return all if all.include? self
        all << self
        self.shift_keys.each do |key|
            self.shiftables(key).each do |rs|
            end
        end
        return all
    end

    def shiftables(key)
        return self.select {|rs|
            rs.pos < rs.exp.size &&
                rs.exp[rs.pos] == key
        }
    end

    # can_shift? and num_reductions:
    # may want to cache the results at some point

    def can_shift?
        # it would be nice if Set had something like
        # self.include? {|x| ...}
        # (I know that would not benefit from O(1) efficiency, but
        # it would be better than this...
        # It could be present on array as well.)
        return !shift_keys.empty?
    end

    def num_reductions
        return self.map {|rs|
            rs.pos == rs.exp.size ? 1 : 0
        }.inject(&:+)
    end

    def reductions
        return self.select {|rs|
            rs.pos == rs.exp.size
        }
    end

    def shift_keys
        return Set.new self.select {|rs|
            rs.pos < rs.exp.size &&
                rs.exp[rs.pos].terminal?
        }.map {|rs|
            rs.exp[rs.pos]
        }
    end

    def shift(key)
        new_state = ParserState.new @desc
        self.shiftables(key).each {|rs|
            new_state.add RuleState.new(rs.rule, rs.pos + 1)
        }
        new_state.complete
        return new_state
    end

    def reduce
        r = reductions
        raise LalrCompileError, "Cannot reduce" if r.size == 0
        raise LalrCompileError, "Reduce-reduce conflict" if r.size > 1
        r = r[0]
        return shift(r.nterm) # hehe! shift == reduce! all connected is, little one...
    end
end

class ParserDesc < Hash
    def initialize(hash)
        if hash.size != 1
            raise LalrCompileError, "Usage: ParserDesc.new :StartSymbol => { <parser-description> }"
        end
        @start_symbol = hash.keys[0]
        desc = hash[@start_symbol]
        if desc.has_key? :_Start
            raise LalrCompileError, "Parser description already contains :_Start non-terminal (used internally)"
        end
        self.add_rule :_Start, [[@start_symbol]]
        self.add_rules desc
        @start_rule = self[:_Start][0]
    end

    def add_rule(nonterminal, expansions)
        if !nonterminal.non_terminal?
            raise LalrCompileError, "Non-terminal symbol #{nonterminal} should be in CamelCase (Bactrian, not dromeDary)"
        end
        expansions.each do |exp|
            if !self.has_key? nonterminal
                self[nonterminal] = []
            end
            self[nonterminal] << Rule.new(nonterminal, exp)
        end
    end
    
    def add_rules(desc)
        desc.each { |x, y| self.add_rule(x, y) }
    end

    def compile
        start_state = ParserState.new( self, [RuleState.new(@start_rule, 0)] )
        all_states = start_state.compile
        return [start_state, all_states]
    end
end
