module Value
  class Fn < Callable
    def to_s
      "fn(#{params_to_s})"
    end

    def eval(e, env, args)
      apply(e, env, eval_args(e, env, args))
    end

    protected
    def eval_args(e, env, args)
      args.map { |arg| e.eval(env, arg) }
    end
  end
end
