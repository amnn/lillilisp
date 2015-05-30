require 'value'

class Evaluator
  class EvalError   < StandardError; end
  class SyntaxError < StandardError; end

  def eval(env, expr)
    case expr
    when Value::Int
      expr
    when Value::Sym
      env.lookup(expr.name)
    when Value::Cons
      eval_sexp(env, expr)
    when Value::Nil
      raise SyntaxError, "Empty function application! (wat?)"
    else
      raise SyntaxError, "Don't know what to do with AST >>> #{expr} <<<"
    end
  end

  private
  def kw(sym)
    (@kw ||= {})[sym] ||= Value::Sym.new(sym)
  end

  def eval_sexp(env, expr)
    oper = expr.head
    body = expr.tail

    case oper
    when kw(:fn)
      validate_abstraction(body, "fn")
      Value::Fn[abstract(env, body)]
    when kw(:macro)
      validate_abstraction(body, "macro")
      Value::Macro[abstract(env, body)]
    when kw(:def)
      validate_def(body)
      sym, init = body.to_a
      env.define(sym.name, eval(env, init))
    when kw(:if)
      validate_len(3, "if", body)
      c_expr, t_expr, e_expr = body.to_a
      if eval(env, c_expr) == Value::Nil
        eval(env, e_expr)
      else
        eval(env, t_expr)
      end
    when kw(:quote)
      validate_len(1, "quote", body)
      body.head
    else
      callable = eval(env, oper)
      case callable
      when Value::Fn
        callable.block[*body.map { |e| eval(env, e) }]
      when Value::Macro
        eval(env, callable.block[*body])
      else
        raise EvalError, "#{callable} not callable!"
      end
    end
  end

  def abstract(env, expr)
    args = expr.head.map(&:name)
    body = expr.tail
    closure = env.clone

    ->(*vals) {
      closure.push
      args.zip(vals).each do |a, v|
        closure.define(a, v)
      end

      body.reduce(nil) do |_, e|
        eval(closure, e)
      end
    }
  end

  def validate_len(len, keyword, expr)
    unless expr.to_a.count == len
      raise SyntaxError, "#{keyword} expects #{len} parts"
    end
  end

  def validate_min_len(min_len, keyword, expr)
    unless expr.to_a.count >= min_len
      raise SyntaxError, "#{keyword} expects at-least #{min_len} parts"
    end
  end

  def validate_abstraction(expr, part)
    validate_min_len(2, part, expr)

    unless Value.sexp? expr.head
      puts expr.head
      raise SyntaxError, "No arg-list provided!"
    end

    unless expr.head.all? { |v| v.is_a? Value::Sym }
      raise SyntaxError, "Bad arg-list"
    end
  end

  def validate_def(expr)
    validate_len(2, "def", expr)
    unless expr.head.is_a? Value::Sym
      raise SyntaxError, "Variable name is not a symbol"
    end
  end
end
