require 'evaluator/validate'

class Evaluator
  class Keyword
    include Validate

    def initialize(evaluator)
      @evaluator = evaluator
    end

    protected
    attr_reader :evaluator
  end
end
