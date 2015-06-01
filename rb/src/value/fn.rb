module Value
  class Fn < Callable
    def to_s
      "fn(#{params_to_s})"
    end

    def eval(e, env, args)
      apply(e, args.map { |arg| e.eval(env, arg) })
    end
  end
end
