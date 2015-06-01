module Value
  class Fn < Callable
    def to_s
      "fn(#{params_to_s})"
    end
  end
end
