class ParseError < StandardError
end

class Parser
    def initialize(lalr, stream)
        @state = lalr
        @states = [lalr]
        @tokens = []
        @stream = stream
    end

    def progress
        if @state.shift_tab.has_key?(@stream.peek)
            @state = @state.shift_tab[@stream.peek]
            @states << @state
            @tokens << @stream.next # not sure I like the stream paradigm I'm using here - error prone
            return true
        end
        @state.reduce_lookup.each do |size, hash|
            parent_idx = -size - 1
            if size < @states.size && hash.has_key? @states[parent_idx]
                rr = hash[@states[parent_idx]]
                @state = rr.next # think I might rename this to ReduceRule.state after all
                @states = @states[0..parent_idx] + [rr.next]
                @tokens = @tokens[0...parent_idx] + [rr.nterm]
                return true
            end
        end
        return false
    end

    def debug
        while progress
            p @tokens
        end
        print "Final state: #{@tokens.inspect}"
    end
end
