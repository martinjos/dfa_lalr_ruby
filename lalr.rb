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

class ReduceRule
    attr :nterm
    attr :size
    attr :parent
    attr :next, true
    def initialize(nterm, size, parent)
        @nterm = nterm
        @size = size
        @parent = parent
    end
end

class ParserContext < Set

    attr :shift_tab
    attr :reduce_tab
    attr :reduce_lookup

    def initialize(desc, elems=[])
        @desc = desc
        @shift_tab = {}
        @reduce_tab = {}
        @reduce_lookup = Hash.new {|h, k| h[k] = {} }
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

    def compile
        allhash = {}
        self.compile_rec(allhash)
        allhash.each_key do |pc|
            pc.final_setup
        end
        return Set.new( allhash.keys )
    end

    def compile_rec(all, stack=[], reduces_done=Set.new, stack_done=Set.new)
        self.complete
        if !all.has_key? self
            all[self] = self
        end
        if stack_done.include?(stack + [self])
            return all[self]
        end
        stack_done << (stack + [self])
        all[self].compile_traverse(all, stack, reduces_done, stack_done)
        return all[self]
    end

    def compile_traverse(all, stack, reduces_done, stack_done)
        stack += [self] # N.B: creates new Array object
        red = self.reductions
        raise LalrCompileError, "Reduce-reduce conflict" if red.size > 1
        self.shift_keys.each do |key|
            #puts " " * (stack.size-1) + "Shift #{key.is_a?(String) ? key : "(#{key})"}"
            @shift_tab[key] = self.shift(key).compile_rec(all, stack, reduces_done, stack_done)
        end
        if red.size > 0
            parent_pos = -red[0].exp.size - 1
            parent = stack[parent_pos]
            # Don't let it do the same reduction with the same parent
            # on the same construction branch
            if !reduces_done.include?([self, parent])
                #puts " " * (stack.size-1) + "Reduce (#{red[0].nterm})"
                # N.B: reduces_done guards against infinite recursion
                # (still not sure this is the best way - seems very inefficient)
                reduces_done << [self, parent]
                next_state = parent.shift(red[0].nterm)
                    .compile_rec(all, stack[0 .. parent_pos], reduces_done, stack_done)
                reduces_done.delete [self, parent]

                @reduce_tab[parent] = ReduceRule.new(red[0].nterm, red[0].exp.size, parent)
                @reduce_tab[parent].next = next_state
            else
                #puts " " * (stack.size-1) + "Guarded against reduction (#{red[0].nterm})"
            end
        end
        if !@shift_tab.empty? && !@reduce_tab.empty?
            @desc.have_sr_conflict = true
        end
    end

    def final_setup
        @reduce_tab.each do |parent, rr|
            @reduce_lookup[rr.size][parent] = rr
        end
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
        new_state = ParserContext.new @desc
        self.shiftables(key).each {|rs|
            new_state.add RuleState.new(rs.rule, rs.pos + 1)
        }
        return new_state
    end
end

class ParserDesc < Hash

    attr :have_sr_conflict, true
    
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
        start_state = ParserContext.new( self, [RuleState.new(@start_rule, 0)] )
        all_states = start_state.compile
        return [start_state, all_states]
    end
end
