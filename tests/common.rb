class Assertion < Exception
end

def assert(cond)
    raise Assertion if !cond
end

def safe
    puts "Survived"
end
