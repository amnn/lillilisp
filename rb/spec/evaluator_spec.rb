require 'value_helper'
require 'evaluator'

RSpec.describe Evaluator do
  include ValueHelper
  let(:env)  { Environment.new }
  let(:e)    { Evaluator.new }

  describe "if" do
    let(:t_pt) { int(1) }
    let(:e_pt) { int(2) }
    let(:expr) { sexp(sym(:if), cond, t_pt, e_pt) }

    context "when condition evaluates to nil" do
      let(:cond) { sexp(sym(:quote), sexp()) }
      it "evaluates the third sub-expression" do
        expect(e.eval(env, expr)).to eq(e_pt)
      end
    end

    context "when condition evaluates to non-nil" do
      let(:cond) { int(1) }
      it "evaluate the second sub-expression" do
        expect(e.eval(env, expr)).to eq(t_pt)
      end
    end
  end

  describe "quote" do
    let(:expr) { sexp(sym(:fn), sexp(sym(:x)), sym(:x)) }
    let(:quoted) { sexp(sym(:quote), expr) }

    it "promotes the AST of its parameter to a value" do
      expect(e.eval(env, quoted)).to eq(expr)
    end
  end

  describe "def" do
    let(:var) { sym(:x) }
    let(:val_1) { int(1) }
    let(:val_2) { int(2) }
    let(:def_1) { sexp(sym(:def), var, val_1) }
    let(:def_2) { sexp(sym(:def), var, val_2) }

    it "modifies the environment" do
      e.eval(env, def_1)
      expect(e.eval(env, var)).to eq(val_1)
    end

    it "overwrites existing definitions" do
      e.eval(env, def_1)
      e.eval(env, def_2)
      expect(e.eval(env, var)).to eq(val_2)
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
  end
end
