require 'tokenizer'

module TokHelper
  def tok(type, val = nil)
    Tokenizer::Token[type, val]
  end

  def sym_list(*syms)
    syms.map { |s| tok(:SYM, s) }
  end

  def tokenize(input)
    Tokenizer.new(input).to_a
  end
end
