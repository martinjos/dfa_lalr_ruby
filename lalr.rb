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
                    if nextsym[0] != nextsym[0].upcase
                        raise LalrCompileError.new("Non-terminal symbol #{nextsym} should be in CamelCase")
                    end
                    fdesc[nextsym].each do |rule|
                        nrs = RuleState.new(rule, 0)
                        if !self.include? nrs
                            list << nrs
                            self << nrs
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
end

class ParserDesc < Hash
    def initialize(hash)
        self.merge! hash
    end
    
    # in effect, this is just augmenting each (sub-)rule with its nonterminal...
    # I may rethink this at some point
    def flatten(start_token)
        flat_desc = ParserDesc.new({ :_Start => [Rule.new(:_Start, [start_token])] })
        self.each do |nonterminal, expansions|
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

    def compile(start_token)
        if self.has_key? :_Start
            raise LalrCompileError, "LALR description already contains :_Start token (used internally)"
        end
        fdesc = self.flatten(start_token)
        start_rule = fdesc[:_Start][0]
        start_state = ParserState.new( [RuleState.new(start_rule, 0)] )
        start_state.complete(fdesc)
        return start_state
    end
end
