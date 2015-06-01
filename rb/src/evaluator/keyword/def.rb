require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    Def = Keyword.kw(:def) do
      def self.validate(body)
        exact_len? 2, "def", body
        name = body.head
        unless name.is_a? Value::Sym
          raise SyntaxError, "`def` expects a symbol, received `#{name}`."
        end
      end

      def self.eval(e, env, body)
        sym, init = body.to_a
        e.eval(env, init).tap do |val|
          env.define(sym.name, val)
        end
      end
    end
  end
end
