require 'evaluator/validator'

class Evaluator
  class KeywordHandler
    def initialize(evaluator)
      @e = evaluator
    end

    def kw_method(s)
      "eval_#{s.name}"
    end

    def handles?(sym)
      sym.is_a?(Value::Sym) && respond_to?(kw_method(sym))
    end

    def __eval(sym, env, body)
      self.send(kw_method(sym), env, body)
    end

    def eval_fn(env, body)
      validator.abstraction? body, "fn"
      Value::Fn.new(env, body)
    end

    def eval_macro(env, body)
      validator.abstraction? body, "macro"
      Value::Macro.new(env, body)
    end

    def eval_def(env, body)
      validator.def? body
      sym, init = body.to_a
      env.define(sym.name, @e.eval(env, init))
    end

    def eval_if(env, body)
      validator.exact_len? 3, "if", body
      c_expr, t_expr, e_expr = body.to_a
      if @e.eval(env, c_expr) == Value::Nil
        @e.eval(env, e_expr)
      else
        @e.eval(env, t_expr)
      end
    end

    def eval_quote(env, body)
      validator.exact_len? 1, "quote", body
      body.head
    end

    private
    def validator
      @validator ||= Validator.new
    end
  end
end
