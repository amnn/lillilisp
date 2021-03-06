require 'primitives'
require 'environment'
require 'value'

RSpec.describe Primitives do
  include Value::Helpers

  let(:env) do
    env = Environment.new
    Primitives.load(env)
    env
  end

  let(:e) { Evaluator.new }

  let(:an_int) { int(1) }
  let(:a_sym)  { sym(:foo) }
  let(:a_str)  { str("foo") }
  let(:a_nil)  { sexp }
  let(:a_list) { sexp(int(1), int(2)) }
  let(:a_cell) { cons(int(1), int(2)) }
  let(:some_values) { [an_int, a_sym, a_str, a_nil, a_list, a_cell] }

  let(:id_fn) { sexp(sym(:fn), sexp(sym(:x)), sym(:x)) }
  let(:a_fn)  { prim([]) { |*xs| int(1) } }

  shared_examples_for "it has arity at least" do |vals, lb|
    it "complains when not given at least #{lb} arguments" do
      expect { subject.apply(e, env, instance_exec(&vals).take(lb - 1)) }
        .to raise_error(Evaluator::EvalError)
    end
  end

  shared_examples_for "it has arity at most" do |vals, ub|
    it "complains when not given at most #{ub} arguments" do
      expect { subject.apply(e, env, instance_exec(&vals).take(ub + 1)) }
        .to raise_error(Evaluator::EvalError)
    end
  end

  shared_examples_for "it has exact arity" do |vals, ex|
    it_behaves_like "it has arity at least", vals, ex
    it_behaves_like "it has arity at most", vals, ex
  end

  describe "eval" do
    subject { env.lookup :eval }

    it "evaluates its argument" do
      [an_int, a_str].each do |v|
        expect(subject.apply(e, env, [v])).to eq(v)
      end

      expect(subject.apply(e, env, [sexp(id_fn, an_int)])).to eq(an_int)
    end

    it "evaluates in the current environment" do
      env.define(:x, an_int)
      expect(subject.apply(e, env, [sym(:x)])).to eq(an_int)
    end
  end

  describe "apply" do
    subject { env.lookup :apply }

    it "complains when its first parameter is not a function" do
      expect { subject.apply(e, env, [an_int, an_int, a_list]) }
        .to raise_error(Evaluator::TypeError)
    end

    it "complains when its last argument is not a list" do
      expect { subject.apply(e, env, [a_fn, an_int]) }
        .to raise_error(Evaluator::TypeError)
    end

    it "applies the function to its arguments" do
      expect(subject.apply(e, env, [a_fn, a_list]))
        .to eq(int(1))
    end
  end

  context "Arithmetic Ops" do
    shared_examples_for "a numerical op" do
      it "complains when given non-integer values" do
        some_values
          .select { |v| v != an_int }
          .each do |v|
          expect { subject.apply(e, env, [v]*2) }
            .to raise_error(Evaluator::TypeError)
        end
      end

      it_behaves_like "it has exact arity", ->() { [an_int]*3 }, 2
    end

    describe "$add" do
      subject { env.lookup :'$add' }

      it "adds numbers" do
        expect(subject.apply(e, env, [int(1), int(2)])).to eq(int(3))
      end

      it_behaves_like "a numerical op"
    end

    describe "$sub" do
      subject { env.lookup :'$sub' }

      it "subtracts numbers" do
        expect(subject.apply(e, env, [int(2), int(1)])).to eq(int(1))
      end

      it_behaves_like "a numerical op"
    end

    describe "$mul" do
      subject { env.lookup :'$mul' }

      it "multiplies numbers" do
        expect(subject.apply(e, env, [int(3), int(2)])).to eq(int(6))
      end

      it_behaves_like "a numerical op"
    end

    describe "$div" do
      subject { env.lookup :'$div' }

      it "divides numbers" do
        expect(subject.apply(e, env, [int(4), int(2)])).to eq(int(2))
      end

      it "rounds down" do
        expect(subject.apply(e, env, [int(1), int(2)])).to eq(int(0))
      end

      it_behaves_like "a numerical op", 2
    end

    describe "$mod" do
      subject { env.lookup :'$mod' }

      it "calculates modulo numbers" do
        expect(subject.apply(e, env, [int(3), int(2)])).to eq(int(1))
        expect(subject.apply(e, env, [int(-1), int(2)])).to eq(int(1))
      end

      it_behaves_like "a numerical op", 2
    end
  end

  context "List Ops" do
    describe "cons" do
      subject { env.lookup :cons }

      it "produces a cons cell" do
        expect(subject.apply(e, env, [int(1), int(2)]))
          .to eq(cons(int(1), int(2)))
      end
    end

    shared_examples_for "a list op" do
      it "complains if not given a cons cell" do
        some_values
          .select { |v| ![a_cell, a_list].include?(v) }
          .each do |v|
          expect { subject.apply(e, env, [v]) }
            .to raise_error(Evaluator::TypeError)
        end
      end

      it_behaves_like "it has exact arity", ->() {
        [cons(int(1), int(2)), cons(int(3), int(4))] }, 1
    end

    describe "head" do
      subject { env.lookup :head }

      it "returns the first part of a cons cell" do
        expect(subject.apply(e, env, [a_cell])).to eq(a_cell.head)
      end

      it_behaves_like "a list op"
    end

    describe "tail" do
      subject { env.lookup :tail }

      it "returns the second part of a cons cell" do
        expect(subject.apply(e, env, [a_cell])).to eq(a_cell.tail)
      end

      it_behaves_like "a list op"
    end
  end

  context "Str Ops" do
    let(:not_strings) { some_values.select { |v| v != a_str } }

    describe "print" do
      subject { env.lookup :print }

      it "complains if not given strings" do
        not_strings.each do |v|
          expect { subject.apply(e, env, [v]) }
            .to raise_error(Evaluator::TypeError)
        end
      end

      it "returns a nil value" do
        expect(subject.apply(e, env, [a_str]))
          .to eq(sexp)
      end

      it "prints strings" do
        expect(STDOUT).to receive(:puts).with("foo")
        subject.apply(e, env, [str("foo")])
      end

      it_behaves_like "it has exact arity", ->() { [a_str]*2 }, 1
    end

    describe "str" do
      subject { env.lookup :str }

      it "is the identity on single strings" do
        expect(subject.apply(e, env, [a_str])).to eq(a_str)
      end

      it "converts other objects to strings" do
        not_strings.each do |v|
          expect(subject.apply(e, env, [v])).to eq(str(v.to_s))
        end
      end

      it "joins operands together (without spaces)" do
        expect(subject.apply(e, env, [str("foo"), str("bar")]))
          .to eq(str("foobar"))
      end
    end

    describe "char-at" do
      subject { env.lookup :"char-at" }

      it "complains when not given a string and an int" do
        expect { subject.apply(e, env, [str("foo"), str("bar")]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(e, env, [int(1), int(2)]) }
          .to raise_error(Evaluator::TypeError)
      end

      it "returns the character of the string at the given index" do
        expect(subject.apply(e, env, [str("foo"), int(1)])).to eq(str("o"))
      end

      it_behaves_like "it has exact arity", ->() { [a_str, an_int, an_int] }, 2
    end

    describe "sym" do
      subject { env.lookup :"sym" }
      let(:not_symable) { some_values.select { |v| ![a_sym, a_str].include?(v) } }

      it "complains when not given a string or a symbol" do
        not_symable.each do |v|
          expect { subject.apply(e, env, [v]) }
            .to raise_error(Evaluator::TypeError)
        end
      end

      it "is the identity on symbols" do
        expect(subject.apply(e, env, [a_sym]))
          .to eq(a_sym)
      end

      it "converts strings to symbols of the same name" do
        expect(subject.apply(e, env, [a_str]))
          .to eq(sym(a_str.val.to_sym))
      end

      it_behaves_like "it has exact arity", ->() { [a_str]*2 }, 1
    end
  end

  context "Comp Ops" do
    describe "$eq" do
      subject { env.lookup :"$eq" }

      it "returns a truthy value for equal objects" do
        some_values.each do |v|
          expect(subject.apply(e, env, [v, v]))
            .not_to eq(a_nil)
        end
      end

      it "returns a falsey value for unequal objects" do
        expect(subject.apply(e, env, [int(1), int(2)])).to eq(a_nil)
      end

      it_behaves_like "it has exact arity", ->() { [an_int]*3 }, 2
    end

    describe "$lt" do
      subject { env.lookup :"$lt" }

      it "complains if the two values it is given are of different types" do
        expect { subject.apply(e, env, [str("foo"), int(1)]) }
          .to raise_error(Evaluator::TypeError)
      end

      it "returns a truthy value when the 1st value is less than the 2nd" do
        expect(subject.apply(e, env, [int(1), int(2)])).not_to eq(a_nil)
      end

      it "returns a falsey value when the 2nd value is less than the 1st" do
        expect(subject.apply(e, env, [int(2), int(1)])).to eq(a_nil)
      end

      it_behaves_like "it has exact arity", ->() { [an_int]*3 }, 2
    end
  end
end
