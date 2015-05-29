class Parser
  AST = Struct.new(:type, :val)

  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    tok = @tokens.next
    case tok.type
    when :NUM
      AST[:NUM, tok.val]
    when :SYM
      AST[:SYM, tok.val]
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

    AST[:SEXP, list]
  rescue StopIteration
    raise ArgumentError, "Oops: Not enough input"
  end
end
