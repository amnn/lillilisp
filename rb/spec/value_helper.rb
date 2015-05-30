require 'value'

module ValueHelper
  def int(val)
    Value::Int.new(val)
  end

  def sym(name)
    Value::Sym.new(name)
  end

  def sexp(*vals)
    Value.sexp(vals)
  end
end
