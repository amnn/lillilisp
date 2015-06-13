require 'evaluator/keyword_handler'
require 'value'

class Evaluator
  class Keyword
    Macro = KeywordHandler.kw(:macro) do
      def validate(body)
        abstraction? body, "macro"
      end

      def eval(env, body)
        Value::Macro.new(env, body)
      end
    end
  end
end
