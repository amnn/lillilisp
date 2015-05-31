module Value
  Int   = Struct.new(:val)
  Sym   = Struct.new(:name)

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

  class Fn < Callable; end
  class Macro < Callable; end

  Nil = Object.new
  Nil.extend(Enumerable)
  def Nil.each; end
  def Nil.to_a
    []
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
  end

  def self.to_sexp(list)
    list.reverse_each.reduce(Nil) do |rest, val|
      Cons[val, rest]
    end
  end

  def self.sexp?(val)
    val.is_a?(Cons) || val.equal?(Nil)
  end
end
