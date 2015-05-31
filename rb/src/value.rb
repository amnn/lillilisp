module Value
  class Int < Struct.new(:val)
    def to_s
      val.to_s
    end
  end

  class Sym < Struct.new(:name)
    def to_s
      name.to_s
    end
  end

  class Callable < Struct.new(:env, :params, :rest, :body)
    def initialize(env, expr)
      super(env.clone, *formal_params(expr.head), expr.tail)
    end

    def apply(e, args)
      env.elaborate(actual_params(args)) do
        body.reduce(nil) do |_, expr|
          e.eval(env, expr)
        end
      end
    end

    protected
    def params_to_s
      params.join(' ') + (rest ? " & #{rest}" : "")
    end

    private
    def formal_params(args)
      arg_names  = args.map(&:name)
      params     = arg_names.take_while { |n| n != :& }
      _, rest, e = arg_names.drop_while { |n| n != :& }

      if e || rest == :&
        raise Evaluator::SyntaxError, "Badly formed argument list"
      end

      [params, rest]
    end

    def actual_params(vals)
      Hash[params.zip(vals)].tap do |args|
        if rest
          args[rest] = Value.to_sexp(vals.drop(args.count))
        end
      end
    end
  end

  class Fn < Callable
    def to_s
      "fn(#{params_to_s})"
    end
  end

  class Macro < Callable
    def to_s
      "macro(#{params_to_s})"
    end
  end

  Nil = Object.new
  Nil.extend(Enumerable)
  def Nil.each; end
  def Nil.to_a
    []
  end

  def Nil.to_s
    "'()"
  end

  class Cons < Struct.new(:head, :tail)
    include Enumerable
    def each #+yields
      curr = self
      while curr.is_a? Cons
        yield curr.head
        curr = curr.tail
      end
    end

    def to_a
      enum_for(:each).to_a
    end

    def to_s
      if Value.nil_terminated?(self)
        "'(#{enum_for(:each).to_a.join(' ')})"
      else
        "'(#{head} . #{tail})"
      end
    end
  end

  def self.to_sexp(list)
    list.reverse_each.reduce(Nil) do |rest, val|
      Cons[val, rest]
    end
  end

  def self.sexp?(val)
    val.is_a?(Cons) || val.equal?(Nil)
  end

  def self.nil_terminated?(list)
    loop do
      case list
      when Nil
        return true
      when Cons
        list = list.tail
      else
        return false
      end
    end
  end
end
