require 'value'

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    tok = @tokens.next
    case tok.type
    when :NUM
      Value::Int.new(tok.val)
    when :SYM
      Value::Sym.new(tok.val)
    when :BRA
      parseList
    else
      raise ArgumentError, "Oops: Unexpected Token: #{tok}"
    end
  rescue StopIteration
    nil
  end

  def done?
    @tokens.peek; false
  rescue StopIteration
    true
  end

  private
  def parseList
    list = []

    while @tokens.peek.type != :KET
      list << parse
    end
    @tokens.next # Consume KET

    Value.sexp(list)
  rescue StopIteration
    raise ArgumentError, "Oops: Not enough input"
  end
end
