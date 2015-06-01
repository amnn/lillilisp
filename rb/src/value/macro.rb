module Value
  class Macro < Callable
    def to_s
      "macro(#{params_to_s})"
    end
  end
end
