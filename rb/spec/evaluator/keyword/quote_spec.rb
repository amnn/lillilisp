require 'value'
require 'environment'
require 'evaluator/keyword/quote'

RSpec.describe Evaluator::Keyword::Quote do
  include Value::Helpers

  let(:env)    { Environment.new }
  let(:e)      { Evaluator.new }

  let(:expr)   { sexp(sym(:fn), sexp(sym(:x)), sym(:x)) }
  let(:quoted) { sexp(expr) }

  describe ".validate" do
    context "when there is no parameter" do
      let(:quoted) { sexp() }
      it "throws an error" do
        expect { described_class.validate(quoted) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there is more than one parameter" do
      let(:quoted) { sexp(expr, expr) }
      it "throws an error" do
        expect { described_class.validate(quoted) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end
  end

  describe ".eval" do
    it "promotes the AST of its parameter to a value" do
      expect(described_class.eval(e, env, quoted)).to eq(expr)
    end
  end
end
