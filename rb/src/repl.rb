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
  class ExitError < StandardError; end

  class << self
    def top_level
      @tl_writer = Writer::Std.new
      new(Reader::Std.new, tl_writer,
          Primitives.load(Environment.new),
          Evaluator.new)
    end

    def from_file(file)
      new(Reader::File.new(file), tl_writer,
          Primitives.load(Environment.new),
          Evaluator.new)
    end

    def require(file, env, evaluator)
      new(Reader::File.new(file),
          Writer::Req.new(tl_writer),
          env, evaluator)
    end

    def tl_writer
      @tl_writer ||= Writer::Null.new
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
      rescue ExitError
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
  if ARGV.empty?
    REPL.top_level.run
  else
    fname = File.expand_path ARGV.first
    REPL.from_file(fname).step
  end
end
