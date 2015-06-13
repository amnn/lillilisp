require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    Quote = Keyword.kw(:quote) do
      def validate(body)
        exact_len? 1, "quote", body
      end

      def eval(env, body)
        body.head
      end
    end
  end
end
