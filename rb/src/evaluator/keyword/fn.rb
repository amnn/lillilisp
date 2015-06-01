require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    Fn = Keyword.kw(:fn) do
      def self.validate(body)
        abstraction? body, "fn"
      end

      def self.eval(e, env, body)
        Value::Fn.new(env, body)
      end
    end
  end
end
