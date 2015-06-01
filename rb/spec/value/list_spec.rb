require 'value'

RSpec.describe Value::ListHelpers do
  subject do lh = Object.new
    lh.extend Value::ListHelpers
    lh
  end

  describe ".to_sexp" do
    it "returns Nil for the empty list" do
      expect(subject.to_sexp([])).to eq(Value::Nil)
    end

    it "returns a Cons List for non-empty lists" do
      expect(subject.to_sexp([1,2,3]))
        .to eq(Value::Cons[1, Value::Cons[2, Value::Cons[3, Value::Nil]]])
    end
  end

  describe ".sexp?" do
    it "says `Nil` is a valid S-Expression" do
      expect(subject.sexp?(Value::Nil)).to be
    end

    it "says a `Cons` cell is a valid S-Expression" do
      expect(subject.sexp?(Value::Cons[Value::Nil, Value::Nil])).to be
    end

    it "recognises other value types are not S-Expressions" do
      expect(subject.sexp?(Value::Int[1])).not_to be
      expect(subject.sexp?(Value::Sym[:foo])).not_to be
      expect(subject.sexp?(Value::Str["foo"])).not_to be
    end
  end

  describe ".nil_terminated?" do
    it "says `Nil` is a valid S-Expression" do
      expect(subject.sexp?(Value::Nil)).to be
    end

    it "says `Cons` cell is a valid S-Expression" do
      expect(subject.sexp?(Value::Cons[nil, nil])).to be
    end
  end
end
