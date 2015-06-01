require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    Macro = Keyword.kw(:macro) do
      def self.validate(body)
        abstraction? body, "macro"
      end

      def self.eval(e, env, body)
        Value::Macro.new(env, body)
      end
    end
  end
end
