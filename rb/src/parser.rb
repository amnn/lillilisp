require 'value'

class Parser
  class ParseError < StandardError; end

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
      raise ParseError, "Oops: Unexpected Token: #{tok}"
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

    Value.to_sexp(list)
  rescue StopIteration
    raise ParseError, "Oops: Not enough input"
  end
end
