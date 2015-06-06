$LOAD_PATH << File.expand_path('../', __FILE__)

require 'evaluator'
require 'parser'
require 'tokenizer'
require 'environment'
require 'primitives'
require 'error'

class REPL
  def run
    loop do
      begin
        print ">>> "; p = read(gets || "")
        until p.done?
          puts "--> #{eval(p.parse)}"
        end
      rescue Evaluator::ExitError
        puts "Bye!"
        break
      rescue LangError => e
        puts e
      rescue Interrupt
        puts
      end
    end
  end

  private
  def env
    @env ||= Primitives.load Environment.new
  end

  def read(input)
    Parser.new(Tokenizer.stream input)
  end

  def eval(expr)
    evaluator.eval(env, expr)
  end

  def evaluator
    @evaluator ||= Evaluator.new
  end
end

if __FILE__ == $0
  REPL.new.run
end
