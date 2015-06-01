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
      validate_abstraction(body, "fn")
      Value::Fn.new(env, body)
    end

    def eval_macro(env, body)
      validate_abstraction(body, "macro")
      Value::Macro.new(env, body)
    end

    def eval_def(env, body)
      validate_def(body)
      sym, init = body.to_a
      env.define(sym.name, @e.eval(env, init))
    end

    def eval_if(env, body)
      validate_exact_len(3, "if", body)
      c_expr, t_expr, e_expr = body.to_a
      if @e.eval(env, c_expr) == Value::Nil
        @e.eval(env, e_expr)
      else
        @e.eval(env, t_expr)
      end
    end

    def eval_quote(env, body)
      validate_exact_len(1, "quote", body)
      body.head
    end

    def validate_len(keyword, expr, test, err) #+yields
      actual = expr.to_a.count
      unless test.(actual)
        raise SyntaxError, "`#{keyword}` wrong number of parts "\
                           "(#{err.(actual)})."
      end
    end

    def validate_exact_len(len, keyword, expr)
      validate_len(keyword, expr,
                   ->(actual) { actual == len },
                   ->(actual) { "#{actual} for #{len}" })
    end

    def validate_min_len(min_len, keyword, expr)
      validate_len(keyword, expr,
                   ->(actual) { actual >= min_len },
                   ->(actual) { "#{actual} for #{min_len}+" })
    end

    def validate_arg_list(args)
      unless Value.sexp? args
        raise SyntaxError, "Expected argument list, received `#{args}`."
      end

      not_sym = args.reject { |v| v.is_a? Value::Sym }.first
      if not_sym
        raise SyntaxError, "Found `#{not_sym}` (not a symbol) in argument list."
      end
    end

    def validate_abstraction(expr, part)
      validate_min_len(2, part, expr)
      validate_arg_list(expr.head)
    end

    def validate_def(expr)
      validate_exact_len(2, "def", expr)
      name = expr.head
      unless name.is_a? Value::Sym
        raise SyntaxError, "`def` expects a symbol, received `#{name}`."
      end
    end
  end
end
