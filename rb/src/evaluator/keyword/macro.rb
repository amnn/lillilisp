require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    Macro = Keyword.kw(:macro) do
      def validate(body)
        abstraction? body, "macro"
      end

      def eval(env, body)
        Value::Macro.new(env, body)
      end
    end
  end
end
