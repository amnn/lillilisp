require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    If = Keyword.kw(:if) do
      def validate(body)
        exact_len? 3, "if", body
      end

      def eval(env, body)
        c_expr, t_expr, e_expr = body.to_a
        if Value::Nil == evaluator.eval(env, c_expr)
          evaluator.eval(env, e_expr)
        else
          evaluator.eval(env, t_expr)
        end
      end
    end
  end
end
