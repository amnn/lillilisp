$LOAD_PATH << File.expand_path('../', __FILE__)

require 'evaluator'
require 'parser'
require 'tokenizer'
require 'environment'
require 'primitives'
require 'error'
require 'reader'
require 'writer'

class REPL
  class << self
    def top_level
      new(Reader::Std.new,
          Writer::Std.new,
          Primitives.load(Environment.new),
          Evaluator.new)
    end

    def require(file, env, evaluator)
      new(Reader::File.new(file),
          Writer::Req.new,
          env, evaluator)
    end

    def run_file(file, env, evaluator)
      new(Reader::File.new(file),
          Writer::Null.new,
          env, evaluator)
    end
  end

  def initialize(istream, ostream, env, evaluator)
    @in  = istream
    @out = ostream
    @env = env
    @evaluator = evaluator
  end

  def step
    @out.put ">>> "
    p = read(@in.get)
    until p.done?
      @out.ret eval(p.parse)
    end
    true
  rescue LangError => e
    @out.err e
    false
  rescue Interrupt
    @out.putln
    false
  end

  def run
    print_usage
    loop do
      begin
        step
      rescue Evaluator::ExitError
        @out.putln "Bye!"
        break
      end
    end
  end

  private
  def read(input)
    Parser.new(Tokenizer.stream input)
  end

  def eval(expr)
    @evaluator.eval(@env, expr)
  end

  def print_usage
    @out.putln "lillilisp REPL"
    @out.putln "Type (exit) to quit"
    @out.putln
  end
end

if __FILE__ == $0
  REPL.top_level.run
end
