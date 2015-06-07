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

  let(:an_int) { int(1) }
  let(:a_sym)  { sym(:foo) }
  let(:a_str)  { str("foo") }
  let(:a_nil)  { sexp }
  let(:a_list) { sexp(int(1), int(2)) }
  let(:a_cell) { cons(int(1), int(2)) }

  shared_examples_for "it has arity at least" do |vals, lb|
    it "complains when not given at least #{lb} arguments" do
      expect { subject.apply(env, instance_exec(&vals).take(lb - 1)) }
        .to raise_error(Evaluator::EvalError)
    end
  end

  shared_examples_for "it has arity at most" do |vals, ub|
    it "complains when not given at most #{ub} arguments" do
      expect { subject.apply(env, instance_exec(&vals).take(ub + 1)) }
        .to raise_error(Evaluator::EvalError)
    end
  end

  shared_examples_for "it has exact arity" do |vals, ex|
    it_behaves_like "it has arity at least", vals, ex
    it_behaves_like "it has arity at most", vals, ex
  end

  context "Arithmetic Ops" do
    shared_examples_for "a numerical op" do |arity = 1|
      it "complains when given non-integer values" do
        expect { subject.apply(env, [a_str]*arity) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_sym]*arity) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_nil]*arity) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_list]*arity) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_cell]*arity) }
          .to raise_error(Evaluator::TypeError)
      end
    end

    describe "+" do
      subject { env.lookup :+ }

      it "returns 0 when called with no arguments" do
        expect(subject.apply(env, [])).to eq(int(0))
      end

      it "is the identity for one argument" do
        expect(subject.apply(env, [int(1)])).to eq(int(1))
      end

      it "adds more than two arguments together" do
        expect(subject.apply(env, [int(1), int(2)])).to eq(int(3))
        expect(subject.apply(env, [int(1), int(2), int(3)])).to eq(int(6))
      end

      it_behaves_like "a numerical op"
    end

    describe "-" do
      subject { env.lookup :- }

      it "negates its argument if there is only one" do
        expect(subject.apply(env, [int(1)])).to eq(int(-1))
      end

      it "subtracts the arguments from left to right if more than one given" do
        expect(subject.apply(env, [int(2), int(1)])).to eq(int(1))
        expect(subject.apply(env, [int(3), int(2), int(1)])).to eq(int(0))
      end

      it_behaves_like "a numerical op"
      it_behaves_like "it has arity at least", ->() { [an_int] }, 1
    end

    describe "*" do
      subject { env.lookup :* }

      it "returns 1 when called with no arguments" do
        expect(subject.apply(env, [])).to eq(int(1))
      end

      it "is the identity for one argument" do
        expect(subject.apply(env, [int(1)])).to eq(int(1))
      end

      it "multiplies more than one argument together" do
        expect(subject.apply(env, [int(1), int(2)])).to eq(int(2))
        expect(subject.apply(env, [int(1), int(2), int(4)])).to eq(int(8))
      end

      it_behaves_like "a numerical op"
    end

    describe "/" do
      subject { env.lookup :/ }

      it "divides more than two numbers from left to right" do
        expect(subject.apply(env, [int(4), int(2)])).to eq(int(2))
        expect(subject.apply(env, [int(8), int(4), int(2)])).to eq(int(1))
      end

      it "rounds down" do
        expect(subject.apply(env, [int(1), int(2)])).to eq(int(0))
      end

      it_behaves_like "a numerical op", 2
      it_behaves_like "it has arity at least", ->() { [an_int, an_int] }, 2
    end

    describe "%" do
      subject { env.lookup :% }

      it "complains when not given exactly 2 arguments" do
        expect { subject.apply(env, [int(1)]) }
          .to raise_error(Evaluator::EvalError)

        expect { subject.apply(env, [int(1), int(2), int(3)]) }
          .to raise_error(Evaluator::EvalError)
      end

      it "(% x y) evaluates to x mod y" do
        expect(subject.apply(env, [int(3), int(2)])).to eq(int(1))
        expect(subject.apply(env, [int(-1), int(2)])).to eq(int(1))
      end

      it_behaves_like "a numerical op", 2
      it_behaves_like "it has exact arity", ->() { [an_int, an_int, an_int] }, 2
    end
  end

  context "List Ops" do
    describe "cons" do
      subject { env.lookup :cons }

      it "produces a cons cell" do
        expect(subject.apply(env, [int(1), int(2)])).to eq(cons(int(1), int(2)))
      end
    end

    shared_examples_for "a list op" do
      it "complains if not given a cons cell" do
        expect { subject.apply(env, [a_nil]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [an_int]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_str]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_sym]) }
          .to raise_error(Evaluator::TypeError)
      end

      it_behaves_like "it has exact arity", ->() { [cons(int(1), int(2)),
                                                    cons(int(3), int(4))] }, 1
    end

    describe "head" do
      subject { env.lookup :head }

      it "returns the first part of a cons cell" do
        expect(subject.apply(env, [a_cell])).to eq(a_cell.head)
      end

      it_behaves_like "a list op"
    end

    describe "tail" do
      subject { env.lookup :tail }

      it "returns the second part of a cons cell" do
        expect(subject.apply(env, [a_cell])).to eq(a_cell.tail)
      end

      it_behaves_like "a list op"
    end
  end

  context "Str Ops" do
    describe "print" do
      subject { env.lookup :print }

      it "complains if not given strings" do
        expect { subject.apply(env, [a_sym]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [an_int]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_cell]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_nil]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [a_list]) }
          .to raise_error(Evaluator::TypeError)
      end

      it "returns a nil value" do
        expect(subject.apply(env, []))
          .to eq(sexp)
      end

      it "prints strings" do
        expect(STDOUT).to receive(:puts).with("foo")
        subject.apply(env, [str("foo")])
      end

      it "separates multiple arguments with spaces" do
        expect(STDOUT).to receive(:puts).with("foo bar")
        subject.apply(env, [str("foo"), str("bar")])
      end
    end

    describe "str" do
      subject { env.lookup :str }

      it "is the identity on single strings" do
        expect(subject.apply(env, [a_str])).to eq(a_str)
      end

      it "converts other objects to strings" do
        expect(subject.apply(env, [a_sym])).to eq(str(a_sym.to_s))
        expect(subject.apply(env, [an_int])).to eq(str(an_int.to_s))
        expect(subject.apply(env, [a_cell])).to eq(str(a_cell.to_s))
        expect(subject.apply(env, [a_nil])).to eq(str(a_nil.to_s))
        expect(subject.apply(env, [a_list])).to eq(str(a_list.to_s))
      end

      it "joins operands together (without spaces)" do
        expect(subject.apply(env, [str("foo"), str("bar")]))
          .to eq(str("foobar"))
      end
    end

    describe "char-at" do
      subject { env.lookup :"char-at" }

      it "complains when not given a string and an int" do
        expect { subject.apply(env, [str("foo"), str("bar")]) }
          .to raise_error(Evaluator::TypeError)

        expect { subject.apply(env, [int(1), int(2)]) }
          .to raise_error(Evaluator::TypeError)
      end

      it "returns the character of the string at the given index" do
        expect(subject.apply(env, [str("foo"), int(1)])).to eq(str("o"))
      end

      it_behaves_like "it has exact arity", ->() { [a_str, an_int, an_int] }, 2
    end
  end

  context "Comp Ops" do
    describe "=" do
      subject { env.lookup :"=" }

      it "returns a truthy value for equal objects" do
        expect(subject.apply(env, [an_int, an_int])).not_to eq(a_nil)
        expect(subject.apply(env, [a_sym, a_sym])).not_to eq(a_nil)
        expect(subject.apply(env, [a_str, a_str])).not_to eq(a_nil)
        expect(subject.apply(env, [a_nil, a_nil])).not_to eq(a_nil)
        expect(subject.apply(env, [a_cell, a_cell])).not_to eq(a_nil)
        expect(subject.apply(env, [a_list, a_list])).not_to eq(a_nil)
      end

      it "returns a falsey value for unequal objects" do
        expect(subject.apply(env, [int(1), int(2)])).to eq(a_nil)
      end

      it_behaves_like "it has exact arity", ->() { [an_int]*3 }, 2
    end

    describe "<" do
      subject { env.lookup :"<" }

      it "only works on strings or ints" do
        expect { subject.apply(env, [sym(:foo), sym(:bar)]) }
          .to raise_error(Evaluator::TypeError)
      end

      it "complains if the two values it is given are of different types" do
        expect { subject.apply(env, [str("foo"), int(1)]) }
          .to raise_error(Evaluator::TypeError)
      end

      it "returns a truthy value when the 1st value is less than the 2nd" do
        expect(subject.apply(env, [int(1), int(2)])).not_to eq(a_nil)
      end

      it "returns a falsey value when the 2nd value is less than the 1st" do
        expect(subject.apply(env, [int(2), int(1)])).to eq(a_nil)
      end

      it_behaves_like "it has exact arity", ->() { [an_int]*3 }, 2
    end
  end
end
