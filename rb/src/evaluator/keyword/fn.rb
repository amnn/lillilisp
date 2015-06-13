require 'evaluator/keyword_handler'
require 'value'

class Evaluator
  class Keyword
    Fn = KeywordHandler.kw(:fn) do
      def validate(body)
        abstraction? body, "fn"
      end

      def eval(env, body)
        Value::Fn.new(env, body)
      end
    end
  end
end
