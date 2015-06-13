require 'value'
require 'environment'
require 'evaluator/keyword/def'

RSpec.describe Evaluator::Keyword::SetBang do
  include Value::Helpers

  let(:env)  { Environment.new }
  let(:e)    { Evaluator.new }
  subject    { described_class.new(e) }

  let(:var)   { sym(:x) }
  let(:val_1) { int(1) }; let(:set_1) { sexp(var, val_1) }
  let(:val_2) { int(2) }; let(:set_2) { sexp(var, val_2) }

  before do
    env.define(var.name, val_1)
  end

  describe ".validate" do
    it "complains if not given exactly two arguments" do
      expect { subject.validate(sexp(var)) }
        .to raise_error(Evaluator::SyntaxError)
    end

    it "complains if its first argument is not a symbol" do
      expect { subject.validate(sexp(val_1, val_2)) }
        .to raise_error(Evaluator::SyntaxError)
    end
  end

  describe ".eval" do
    let(:bad) { sym(:y) }

    it "complains if the variable has not been defined" do
      expect { subject.eval(env, sexp(bad, val_1)) }
        .to raise_error(Environment::SymbolError)
    end

    it "updates the binding" do
      subject.eval(env, set_2)
      expect(env.lookup(var.name)).to eq(val_2)
    end
  end
end
