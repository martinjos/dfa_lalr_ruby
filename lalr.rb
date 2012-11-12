require 'set'

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

def compile_lalr(desc, start_token)
    if desc.has_key? :_Start
        raise LalrCompileError, "LALR description already contains :_Start token (used internally)"
    end
    fdesc = flatten_desc(desc, start_token)
    start_rule = fdesc[:_Start][0]
    start_state = Set.new( [RuleState.new(start_rule, 0)] )
    complete_state(fdesc, start_state)
    return start_state
end

def complete_state(fdesc, state)
    list = state.to_a
    while rs = list.shift
        if rs.pos < rs.exp.size
            nextsym = rs.exp[rs.pos]
            if fdesc.has_key? nextsym
                if nextsym[0] != nextsym[0].upcase
                    raise LalrCompileError.new("Non-terminal symbol #{nextsym} should be in CamelCase")
                end
                fdesc[nextsym].each do |rule|
                    nrs = RuleState.new(rule, 0)
                    if !state.include? nrs
                        list << nrs
                        state << nrs
                    end
                end
            else
                if nextsym[0] != nextsym[0].downcase
                    raise LalrCompileError.new("Terminal symbol #{nextsym} should be in lower_case")
                end
            end
        end
    end
end

# in effect, this is just augmenting each (sub-)rule with its nonterminal...
# I may rethink this at some point
def flatten_desc(desc, start_token)
    flat_desc = {:_Start => [Rule.new(:_Start, [start_token])]}
    desc.each do |nonterminal, expansions|
        if nonterminal[0] != nonterminal[0].upcase
            raise LalrCompileError, "Non-terminal symbol #{nonterminal} should be in CamelCase"
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
