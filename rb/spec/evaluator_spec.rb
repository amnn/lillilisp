require 'value'
require 'environment'
require 'evaluator'

RSpec.describe Evaluator do
  include Value::Helpers
  let(:env)  { Environment.new }
  let(:e)    { Evaluator.new }

  describe "constants" do
    it "evaluates numbers" do
      expect(e.eval(env, int(1))).to eq(int(1))
    end

    it "evaluates strings" do
      expect(e.eval(env, str("foo"))).to eq(str("foo"))
    end
  end

  shared_examples_for "a callable" do |kw|
    let(:ident) { sym(kw) }

    context "when there are no args or body" do
      let(:no_args_body) { sexp(ident) }
      it "throws an error" do
        expect { e.eval(env, no_args_body) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there are no args" do
      let(:no_args) { sexp(ident, int(1)) }
      it "throws an error" do
        expect { e.eval(env, no_args) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there are multiple rest symbols" do
      let(:mult_rest) { sexp(ident, sexp(sym(:&), sym(:&)), int(1)) }
      it "throws an error" do
        expect { e.eval(env, mult_rest) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there are multiple rest params" do
      let(:mult_rest_p) { sexp(ident, sexp(sym(:&), sym(:x), sym(:y)), int(1)) }
      it "throws an error" do
        expect { e.eval(env, mult_rest_p) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there is no body" do
      let(:no_body) { sexp(ident, sexp()) }
      it "throws an error" do
        expect { e.eval(env, no_body) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when there are non-symbols in the arg-list" do
      let(:bad_args) { sexp(ident, sexp(int(1)), int(1)) }
      it "throws an error" do
        expect { e.eval(env, bad_args) }
          .to raise_error(Evaluator::SyntaxError)
      end
    end

    context "when it is applied to too many arguments" do
      let(:too_many_args) { sexp(sexp(ident, sexp(), int(1)), int(1)) }
      it "throws an error" do
        expect { e.eval(env, too_many_args) }
          .to raise_error(Evaluator::EvalError)
      end
    end

    context "when it is applied to too few arguments" do
      let (:too_few_args) { sexp(sexp(ident, sexp(sym(:x)), int(1))) }
      it "throws an error" do
        expect { e.eval(env, too_few_args) }
          .to raise_error(Evaluator::EvalError)
      end
    end
  end

  describe "fn" do
    let(:id) { sexp(sym(:fn), sexp(sym(:x)), sym(:x))}

    let(:outer)   { sym(:y) }
    let(:val)     { int(1) }
    let(:closure) { sexp(sym(:fn), sexp(sym(:x)), outer) }
    let(:shadow)  { sexp(sym(:fn), sexp(outer), outer) }
    before do
      e.eval(env, sexp(sym(:def), outer, val))
    end

    it "creates a function value" do
      expect(e.eval(env, id)).to be_a(Value::Fn)
    end

    it "closes over its environment" do
      expect(e.eval(env, sexp(closure, int(2)))).to eq(val)
    end

    it "shadows environment variables" do
      expect(e.eval(env, sexp(shadow, int(2)))).to eq(int(2))
    end

    context "rest parameter" do
      let(:with_rest) { sexp(sym(:fn), sexp(sym(:&), sym(:rest)), sym(:rest)) }
      it "captures the rest of the arguments" do
        expect(e.eval(env, sexp(with_rest, int(1))))
          .to eq(sexp(int(1)))
      end

      context "when the rest is empty" do
        let(:empty_rest) { sexp(sym(:fn), sexp(sym(:x), sym(:&)), sym(:x)) }
        it "is ignored" do
          expect(e.eval(env, sexp(empty_rest, int(1))))
            .to eq(int(1))
        end
      end
    end

    it_behaves_like "a callable", :fn
  end

  describe "macro" do
    let(:id_m)   { sexp(sym(:macro), sexp(sym(:x)), sym(:x)) }
    let(:inject) { sexp(sym(:macro), sexp(sym(:x)),
                        sexp(sym(:quote), sym(:y))) }

    let(:outer)  { sym(:y) }
    let(:val)    { int(1) }
    before do
      e.eval(env, sexp(sym(:def), outer, val))
    end

    it "creates a macro value" do
      expect(e.eval(env, id_m)).to be_a(Value::Macro)
    end

    it "is applied before (runtime) evaluation" do
      expect(e.eval(env, sexp(inject, int(1)))).to eq(val)
    end

    it_behaves_like "a callable", :macro
  end
end
