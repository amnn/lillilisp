require 'evaluator/keyword_handler'
require 'value'

class Evaluator
  class Keyword
    SetBang = KeywordHandler.kw(:'set!') do
      def validate(body)
        assignment? body, "set!"
      end

      def eval(env, body)
        sym, update = body.to_a
        evaluator.eval(env, update).tap do |val|
          env.update(sym.name, val)
        end
      end
    end
  end
end
