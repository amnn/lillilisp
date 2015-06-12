require 'value'
require 'environment'
require 'evaluator/keyword/if'

RSpec.describe Evaluator::Keyword::If do
  include Value::Helpers

  let(:env)  { Environment.new }
  let(:e)    { Evaluator.new }

  let(:t_pt) { int(1) }
  let(:e_pt) { int(2) }
  let(:expr) { sexp(cond, t_pt, e_pt) }

  describe ".validate" do
    context "when there are fewer than 3 sub-expressions" do
      let(:expr) { sexp(int(1)) }
      it "throws an error" do
        expect { described_class.validate(expr) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there are more than 3 sub-expressions" do
      let(:expr) { sexp(int(1), t_pt, e_pt, t_pt) }
      it "throws an error" do
        expect { described_class.validate(expr) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end
  end

  describe ".eval" do
    context "when condition evaluates to nil" do
      let(:cond) { sexp(sym(:quote), sexp()) }
      it "evaluates the third sub-expression" do
        expect(described_class.eval(e, env, expr)).to eq(e_pt)
      end
    end

    context "when condition evaluates to non-nil" do
      let(:cond) { int(1) }
      it "evaluate the second sub-expression" do
        expect(described_class.eval(e, env, expr)).to eq(t_pt)
      end
    end
  end
end
