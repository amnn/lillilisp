require 'evaluator/keyword'

class Evaluator
  class KeywordHandler
    class << self
      def kw(name, &init)
        handler_classes[name] =
          Class.new(Keyword, &init)
      end

      def handler_classes
        @handler_classes ||= {}
      end
    end

    def initialize(evaluator)
      self.class.handler_classes.each do |name, klass|
        handlers[name] = klass.new(evaluator)
      end
    end

    def handles?(sym)
      sym.is_a?(Value::Sym) && handlers.key?(sym.name)
    end

    def eval(sym, env, body)
      handlers[sym.name].validate(body)
      handlers[sym.name].eval(env, body)
    end

    require 'evaluator/keyword/fn'
    require 'evaluator/keyword/macro'
    require 'evaluator/keyword/def'
    require 'evaluator/keyword/if'
    require 'evaluator/keyword/quote'
    require 'evaluator/keyword/require'

    protected
    attr_reader :evaluator

    private
    def handlers
      @handlers ||= {}
    end
  end
end
