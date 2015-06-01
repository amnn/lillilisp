module Value
  class Macro < Callable
    def to_s
      "macro(#{params_to_s})"
    end

    def eval(e, env, args)
      e.eval(env, apply(e, args.to_a))
    end
  end
end
