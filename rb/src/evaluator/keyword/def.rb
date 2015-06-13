require 'evaluator/keyword_handler'
require 'value'

class Evaluator
  class Keyword
    Def = KeywordHandler.kw(:def) do
      def validate(body)
        exact_len? 2, "def", body
        name = body.head
        unless name.is_a? Value::Sym
          raise SyntaxError, "`def` expects a symbol, received `#{name}`."
        end
      end

      def eval(env, body)
        sym, init = body.to_a
        evaluator.eval(env, init).tap do |val|
          env.define(sym.name, val)
        end
      end
    end
  end
end
