class Evaluator
  class Validator
    def exact_len?(len, keyword, expr)
      len?(keyword, expr,
           ->(actual) { actual == len },
           ->(actual) { "#{actual} for #{len}" })
    end

    def min_len?(min_len, keyword, expr)
      len?(keyword, expr,
           ->(actual) { actual >= min_len },
           ->(actual) { "#{actual} for #{min_len}+" })
    end

    def arg_list?(args)
      unless Value.sexp? args
        raise SyntaxError, "Expected argument list, received `#{args}`."
      end

      not_sym = args.reject { |v| v.is_a? Value::Sym }.first
      if not_sym
        raise SyntaxError, "Found `#{not_sym}` (not a symbol) in argument list."
      end
    end

    def abstraction?(expr, part)
      min_len? 2, part, expr
      arg_list? expr.head
    end

    def def?(expr)
      exact_len? 2, "def", expr
      name = expr.head
      unless name.is_a? Value::Sym
        raise SyntaxError, "`def` expects a symbol, received `#{name}`."
      end
    end

    private
    def len?(keyword, expr, test, err) #+yields
      actual = expr.to_a.count
      unless test.(actual)
        raise SyntaxError, "`#{keyword}` wrong number of parts "\
                           "(#{err.(actual)})."
      end
    end
  end
end
