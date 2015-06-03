require 'evaluator/validate'
require 'value'

class Evaluator
  class Keyword
    If = Keyword.kw(:if) do
      def self.validate(body)
        exact_len? 3, "if", body
      end

      def self.eval(e, env, body)
        c_expr, t_expr, e_expr = body.to_a
        if Value::Nil == e.eval(env, c_expr)
          e.eval(env, e_expr)
        else
          e.eval(env, t_expr)
        end
      end
    end
  end
end
