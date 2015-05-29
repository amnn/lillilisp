require 'parser'

def ast(type, val = nil)
  Parser::AST[type, val]
end

def parser(*toks)
  Parser.new(toks.to_enum)
end
