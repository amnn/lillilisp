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
  end

  def self.comp_ops(env)
    env.define :'=', prim([]) { |x, y| x == y ? sym(:t) : sexp }

    ordered = [Value::Str, Value::Int]
    env.define :'<', prim([ordered, ordered]) { |x, y|
      unless x.kind_of?(y.class) || y.kind_of?(x.class)
        raise Evaluator::TypeError, "Comparing instances of disparate types: "\
                                    "#{x.class}, #{y.class}"
      end

      x.val < y.val ? sym(:t) : sexp
    }
  end
end
