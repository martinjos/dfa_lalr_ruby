class FunctionLookahead
    def initialize(&p)
        @p = p
        @next = nil
    end

    def next
        if next
            res = @next
            @next = nil
            return res
        end
        return p.call
    end

    def peek
        if !@next
            @next = p.call
        end
        return @next
    end
end
