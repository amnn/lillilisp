require 'evaluator/keyword_handler'
require 'value'

class Evaluator
  class Keyword
    Def = KeywordHandler.kw(:def) do
      def validate(body)
        assignment? body, "def"
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
