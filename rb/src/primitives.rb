require 'value'
require 'evaluator'

module Primitives
  extend Value::Helpers

  def self.load(env)
    env.define :exit, prim([]) { raise Evaluator::ExitError }

    arith_ops(env)
    list_ops(env)
    str_ops(env)
    comp_ops(env)

    env
  end

  def self.arith_ops(env)
    env.define :+, prim([], Value::Int) { |*xs|
      int(xs.reduce(0) { |acc, x| acc + x.val })
    }

    env.define :-, prim([], Value::Int) { |x, *xs|
      int(
        if xs.empty?
          -x.val
        else
          xs.reduce(x.val) { |acc, y| acc - y.val }
        end)
    }

    env.define :*, prim([], Value::Int) { |*xs|
      int(xs.reduce(1) { |acc, x| acc * x.val })
    }

    env.define :/, prim([], Value::Int) { |x,y,*xs|
      int(xs.reduce(x.val/y.val) { |acc, z| acc / z.val })
    }

    env.define :%, prim([Value::Int, Value::Int]) { |x, y|
      int(x.val % y.val)
    }
  end

  def self.list_ops(env)
    env.define :cons, prim([Object, Object]) { |x, xs|
      cons(x, xs)
    }

    env.define :head, prim([Value::Cons]) { |l| l.head }
    env.define :tail, prim([Value::Cons]) { |l| l.tail }
  end

  def self.str_ops(env)
    env.define :print, prim([], Value::Str) { |*xs|
      puts xs.map { |x| x.val }.join(' ')
      sexp
    }

    env.define :str, prim([]) { |*xs|
      str(xs.map { |x| x.is_a?(Value::Str) ? x.val : x.to_s }.join)
    }

    env.define :'char-at', prim([Value::Str, Value::Int]) { |s, i|
        str(s.val[i.val])
    }
  end

  def self.comp_ops(env)
    env.define :'=', prim([]) { |x, y| x == y ? sym(:t) : sexp }

    ordered = [Value::Str, Value::Int]
    env.define :'<', prim([ordered, ordered]) { |x, y|
      x.val < y.val ? sym(:t) : sexp
    }
  end
end
