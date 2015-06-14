require 'value/int'
require 'value/sym'
require 'value/str'
require 'value/list'

module Value
  extend ListHelpers

  module Helpers
    def int(val)
      Value::Int.new(val)
    end

    def sym(name)
      Value::Sym.new(name)
    end

    def str(val)
      Value::Str.new(val)
    end

    def cons(h, t)
      Value::Cons.new(h, t)
    end

    def sexp(*vals)
      Value.to_sexp(vals)
    end

    def prim(param_ts, rest_t = nil, &blk)
      Value::Primitive.new(param_ts, rest_t, &blk)
    end
  end

  require 'value/callable'
  require 'value/fn'
  require 'value/primitive'
  require 'value/macro'
end
