require 'value'
require 'error'
require 'evaluator/keyword'

class Evaluator
  EvalError   = LangError.of_type "Runtime"
  TypeError   = LangError.of_type "Type"
  ExitError   = LangError.of_type "Exit"
  SyntaxError = LangError.of_type "Syntax"

  def eval(env, expr)
    case expr
    when Value::Int
      expr
    when Value::Str
      expr
    when Value::Sym
      env.lookup(expr.name)
    when Value::Cons
      eval_sexp(env, expr)
    when Value::Nil
      raise EvalError, "Empty function application! (wat?)"
    else
      raise SyntaxError, "Don't know what to do with AST `#{expr}`"
    end
  end

  private
  def eval_sexp(env, expr)
    oper = expr.head
    body = expr.tail

    if Keyword.handles?(oper)
      Keyword.eval(self, oper, env, body)
    else
      eval_callable(eval(env, oper),
                    env, body)
    end
  end

  def eval_callable(callable, env, body)
    case callable
    when Value::Callable
      callable.eval(self, env, body)
    else
      raise EvalError, "#{callable} not callable!"
    end
  end
end
