require 'value'

module ValueHelper
  def int(val)
    Value::Int.new(val)
  end

  def sym(name)
    Value::Sym.new(name)
  end

  def str(val)
    Value::Str.new(val)
  end

  def sexp(*vals)
    Value.to_sexp(vals)
  end
end
