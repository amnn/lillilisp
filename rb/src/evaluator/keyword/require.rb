require 'set'

require 'evaluator/keyword_handler'
require 'value'
require 'repl'

class Evaluator
  class Keyword
    Require = KeywordHandler.kw(:require) do
      def validate(body)
        exact_len? 1, "require", body
        arg = body.head
        unless arg.is_a? Value::Str
          raise TypeError, "`require` expects a string, received `#{arg}`."
        end
      end

      def eval(env, body)
        if load_file(fname(body.head), env)
          Value::Sym[:t]
        else
          Value::Nil
        end
      end

      private
      def load_file(fn, env)
        return false if loaded? fn

        REPL.require(fn, env, evaluator)
          .step.tap do |finished|
          files << fn if finished
        end
      end

      def loaded?(fn)
        files.include? fn
      end

      def files
        @files ||= Set[]
      end

      def fname(str)
        File.expand_path str.val
      end
    end
  end
end
