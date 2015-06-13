require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    Fn = Keyword.kw(:fn) do
      def validate(body)
        abstraction? body, "fn"
      end

      def eval(env, body)
        Value::Fn.new(env, body)
      end
    end
  end
end
