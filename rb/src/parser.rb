require 'value'
require 'error'

class Parser
  ParseError = LangError.of_type "Parse"

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
    when :STR
      Value::Str.new(tok.val)
    when :QUOT
      enquote parse
    when :BRA
      parseList
    else
      raise ParseError, "Unexpected Token `#{tok}`."
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
  def enquote(expr)
    raise "Not enough input `(quote\u2026`." unless expr
    Value.to_sexp([Value::Sym[:quote], expr])
  end

  def parseList
    list = []

    while @tokens.peek.type != :KET
      list << parse
    end
    @tokens.next # Consume KET

    Value.to_sexp(list)
  rescue StopIteration
    raise ParseError, "Not enough input `(#{list.join(' ')}\u2026`."
  end
end
