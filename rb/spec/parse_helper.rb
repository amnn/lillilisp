require 'parser'

module ParseHelper
  def parser(*toks)
    Parser.new(toks.to_enum)
  end
end
