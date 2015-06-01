require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    Quote = Keyword.kw(:quote) do
      def self.validate(body)
        exact_len? 1, "quote", body
      end

      def self.eval(e, env, body)
        body.head
      end
    end
  end
end
