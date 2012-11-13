require 'set'

class LexError < StandardError
    def initialize(pos, len)
        if pos == len
            super("at EOF")
        else
            super("at position #{pos}")
        end
    end
end

class Lexer
    def initialize(dfa, duck)
        @dfa = dfa
        @duck = duck
        @size = duck.size
        @start_state = Set.new( [0] )
        @state = @start_state
        @str = ""
        @pos = 0
        @last_success = nil
        @last_str = nil
        @last_pos = nil
    end

    def success(su, s, p)
        if su.size == 1
            retsym = su.first
        else
            retsym = su
        end
        @state = @start_state
        @str = ""
        @last_success = nil # don't bother clearing last_str or last_pos
        return [retsym, s, p]
    end

    # will need to yield everything from duck, possibly
    # backtracking along the way, plus "" to finish off.
    # (no "" transitions can survive compilation)
    def progress_input(ch)
        #puts "At position #{@pos}"
        success = @dfa[@state].success
        if !success.empty?
            @last_success = success
            @last_str = @str
            @last_pos = @pos
        end
        next_state = @dfa[@state].lookup[ch]
        if next_state.nil?
            if @last_success.nil?
                if @str.empty? && @pos == @size && @state == @start_state
                    throw :done
                else
                    #puts "#{@str} #{@pos} #{@size} #{@state.inspect} #{@start_state.inspect}"
                    raise LexError.new(@pos, @size)
                end
            else
                @pos = @last_pos
                return success(@last_success, @last_str, @last_pos)
            end
        else
            @state = next_state
            @str += ch
            @pos += 1
            return nil
        end
    end

    def progress
        if @pos < @size
            return progress_input(@duck[@pos])
        else
            return progress_input("")
        end
    end

    # not sure how efficient it is to be continually putting up/tearing down
    # this catch
    def next
        catch :done do
            while !(info = progress)
                # do nothing - waiting for token
            end
            return info # got token
        end
        return nil # got end of sequence
    end
end

def lex(dfa, duck)
    lexer = Lexer.new(dfa, duck)
    while info = lexer.next
        yield info[0], info[1], info[2]
    end
end
