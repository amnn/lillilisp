require 'value'
require 'environment'
require 'evaluator/keyword/def'

RSpec.describe Evaluator::Keyword::Def do
  include Value::Helpers

  let(:env)  { Environment.new }
  let(:e)    { Evaluator.new }

  let(:var)   { sym(:x) }
  let(:val_1) { int(1) }; let(:def_1) { sexp(var, val_1) }
  let(:val_2) { int(2) }; let(:def_2) { sexp(var, val_2) }

  describe ".validate" do
    context "when there are fewer than 2 parameters" do
      let(:e_def) { sexp(var) }
      it "throws an error" do
        expect { described_class.validate(e_def) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there are more than 2 parameters" do
      let(:e_def) { sexp(var, val_1, val_1) }
      it "throws an error" do
        expect { described_class.validate(e_def) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end
  end

  describe ".eval" do
    it "modifies the environment" do
      described_class.eval(e, env, def_1)
      expect(env.lookup(var.name)).to eq(val_1)
    end

    it "overwrites existing definitions" do
      described_class.eval(e, env, def_1)
      described_class.eval(e, env, def_2)
      expect(env.lookup(var.name)).to eq(val_2)
    end
  end
end
