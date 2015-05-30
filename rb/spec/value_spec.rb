require 'value'

RSpec.describe Value do
  describe ".sexp" do
    it "returns Nil for the empty list" do
      expect(Value.sexp([])).to eq(Value::Nil)
    end

    it "returns a Cons List for non-empty lists" do
      expect(Value.sexp([1,2,3]))
        .to eq(Value::Cons[1, Value::Cons[2, Value::Cons[3, Value::Nil]]])
    end
  end
end
