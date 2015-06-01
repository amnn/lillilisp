require 'evaluator/validate'

class Evaluator
  class Keyword
    class << self
      def kw(name, &init)
        handlers[name] = Class.new(Keyword, &init)
      end

      def handles?(sym)
        sym.is_a?(Value::Sym) && handlers.key?(sym.name)
      end

      def eval(evaluator, sym, env, body)
        handlers[sym.name].validate(body)
        handlers[sym.name].eval(evaluator, env, body)
      end

      private
      def handlers
        @handlers ||= {}
      end
    end
    extend Validate

    require 'evaluator/keyword/fn'
    require 'evaluator/keyword/macro'
    require 'evaluator/keyword/def'
    require 'evaluator/keyword/if'
    require 'evaluator/keyword/quote'

  end
end
