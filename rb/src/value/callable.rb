module Value
  class Callable < Struct.new(:env, :params, :rest, :body)
    def initialize(env, expr)
      super(env.clone, *formal_params(expr.head), expr.tail)
    end

    protected
    def apply(e, args)
      env.elaborate(actual_params(args)) do
        body.reduce(nil) do |_, expr|
          e.eval(env, expr)
        end
      end
    end

    def params_to_s
      (params.join(' ') + (rest ? " & #{rest}" : "")).lstrip
    end

    def formal_params(args)
      arg_names  = args.map(&:name)
      params     = arg_names.take_while { |n| n != :& }
      _, rest, e = arg_names.drop_while { |n| n != :& }

      if e || rest == :&
        raise Evaluator::SyntaxError, "Badly formed argument list `\u2026&"\
                                      "#{[rest, e].compact.join(' ')})`."
      end

      [params, rest]
    end

    def arity_check(vals)
      actual = vals.size
      expect = params.size
      if actual < expect || !rest && actual > expect
        raise Evaluator::EvalError, "Wrong number of arguments for #{self} "\
                                    "(#{actual} for #{expect}#{rest ? '+':''})"
      end
    end

    def actual_params(vals)
      arity_check vals
      Hash[params.zip(vals)].tap do |args|
        if rest
          args[rest] = Value.to_sexp(vals.drop(args.count))
        end
      end
    end
  end
end
