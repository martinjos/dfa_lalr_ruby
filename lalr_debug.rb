class ParserContext

    @@ind = "'"

    def re(n=0, p=nil)
        if p.nil?
            t = reduce_tab.values[n]
        else
            t = reduce_lookup[n][p]
        end
        if t.nil?
            nil
        else
            t.next
        end
    end

    def sh(x)
        shift_tab[x]
    end

    def renums
        reduce_lookup.keys
    end

    def numres
        reduce_tab.size
    end

    def to_s
        a = self.to_a
        maxnterm = a.map{|x| x.nterm.size}.max
        maxlen = a.map{|x| x.exp.size}.max
        maxexp = (0 ... maxlen).map{|i|
            a.map{|x| x.exp[i] ? x.exp[i].size : nil }.select{|x| x }.max
        }
        self.each_with_index.map{|x|
            sprintf("%*s =>", maxnterm, x.nterm) +
            x.exp.each_with_index.map{|y,i| sprintf(" %-*s", maxexp[i], y) }.inject("", &:+) +
            "\n" + (" " * maxnterm) + "   " +
            (0 ... x.exp.size).map{|i| " " + (x.pos==i ? @@ind : " ") + (" " * (maxexp[i]-1)) }.inject("", &:+) +
            (x.pos == x.exp.size ? " #{@@ind}" : "")
        }.join("\n")
    end
end
