require 'set'

require 'evaluator/keyword_handler'
require 'error'
require 'value'
require 'tokenizer'
require 'parser'

class Evaluator
  class Keyword
    Require = KeywordHandler.kw(:require) do
      include Value::Helpers

      FileError = LangError.of_type "File"

      def validate(body)
        exact_len? 1, "require", body
        arg = body.head
        unless arg.is_a? Value::Str
          raise TypeError, "`require` expects a string, received `#{fname}`."
        end
      end

      def eval(env, body)
        fn = fname(body.head)
        if !loaded?(fn) && load_file(fn, env)
          sym(:t)
        else
          sexp
        end
      end

      private
      def load_file(fn, env)
        File.open(fn) do |f|
          p = read(f)
          until p.done?
            puts "~~> #{eval(env, p.parse)}"
          end
        end

        files << fn
        true
      rescue Errno::ENOENT
        raise FileError, "No such file, `#{fn}`"
      rescue LangError => e
        puts e; false
      end

      def loaded?(fn)
        files.include? fn
      end

      def read(f)
        Parser.new(Tokenizer.stream f.read)
      end

      def eval(env, expr)
        evaluator.eval(env, expr)
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
