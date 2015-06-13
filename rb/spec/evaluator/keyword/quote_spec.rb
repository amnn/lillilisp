require 'value'
require 'environment'
require 'evaluator/keyword/quote'

RSpec.describe Evaluator::Keyword::Quote do
  include Value::Helpers

  let(:env)    { Environment.new }
  let(:e)      { Evaluator.new }
  subject      { described_class.new(e) }

  let(:expr)   { sexp(sym(:fn), sexp(sym(:x)), sym(:x)) }
  let(:quoted) { sexp(expr) }

  describe ".validate" do
    context "when there is no parameter" do
      let(:quoted) { sexp() }
      it "throws an error" do
        expect { subject.validate(quoted) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there is more than one parameter" do
      let(:quoted) { sexp(expr, expr) }
      it "throws an error" do
        expect { subject.validate(quoted) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end
  end

  describe ".eval" do
    it "promotes the AST of its parameter to a value" do
      expect(subject.eval(env, quoted)).to eq(expr)
    end
  end
end
