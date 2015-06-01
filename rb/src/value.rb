require 'value/int'
require 'value/sym'
require 'value/str'
require 'value/list'

require 'value/callable'
require 'value/fn'
require 'value/macro'

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

    def sexp(*vals)
      Value.to_sexp(vals)
    end
  end
end
