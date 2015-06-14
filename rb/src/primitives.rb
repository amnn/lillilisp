require 'value'
require 'evaluator'

module Primitives
  extend Value::Helpers

  def self.load(env)
    env.define :exit, prim([]) { raise Evaluator::ExitError }
    env.define :eval, prim([]) { |expr| evaluator.eval(env, expr) }
    env.define :apply, prim([Value::Fn]) { |f, x, *args|
      *prep, rest = args.unshift(x)

      unless Value.nil_terminated?(rest)
        raise Evaluator::TypeError,
              "`apply` expects last parameter to be a "\
              "list, received `#{rest}`."
      end

      f.apply(evaluator, env,
              Value.to_sexp(prep, rest))
    }

    arith_ops(env)
    list_ops(env)
    str_ops(env)
    comp_ops(env)

    env
  end

  def self.int_prim(&op)
    prim([Value::Int, Value::Int]) { |x, y| int(op[x.val, y.val]) }
  end

  def self.arith_ops(env)
    env.define :'$add', int_prim(&:+)
    env.define :'$sub', int_prim(&:-)
    env.define :'$mul', int_prim(&:*)
    env.define :'$div', int_prim(&:/)
    env.define :'$mod', int_prim(&:%)
  end

  def self.list_ops(env)
    env.define :cons, prim([Object, Object]) { |x, xs| cons(x, xs) }
    env.define :head, prim([Value::Cons])    { |l| l.head }
    env.define :tail, prim([Value::Cons])    { |l| l.tail }
  end

  def self.str_ops(env)
    env.define :print, prim([Value::Str]) { |s| puts s.val; sexp }

    env.define :str, prim([]) { |*xs|
      str(xs.map { |x| x.is_a?(Value::Str) ? x.val : x.to_s }.join)
    }

    env.define :'char-at', prim([Value::Str, Value::Int]) { |s, i|
      str(s.val[i.val])
    }

    env.define :'sym', prim([[Value::Str, Value::Sym]]) { |s|
      s.is_a?(Value::Sym) ? s : sym(s.val.to_sym)
    }
  end

  def self.equate(x, y)
    x == y
  end

  def self.compare(x, y)
    case x
    when Value::Int, Value::Str
      x.val < y.val
    when Value::Sym
      puts "Compare Sym #{x}, #{y}"
      x.name < y.name
    when Value::Cons
      compare(x.head, y.head) ||
        (equate(x.head, y.head) &&
         compare(x.tail, y.tail))
    end
  end

  def self.comp_ops(env)
    env.define :'$eq', prim([]) { |x, y|
      Primitives.equate(x, y) ? sym(:t) : sexp
    }

    env.define :'$lt', prim([]) { |x, y|
      unless x.kind_of?(y.class) || y.kind_of?(x.class)
        raise Evaluator::TypeError, "Comparing instances of disparate types: "\
                                    "#{x.class}, #{y.class}"
      end

      Primitives.compare(x, y) ? sym(:t) : sexp
    }
  end
end
