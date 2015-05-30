require 'environment'

RSpec.describe Environment do
  subject { Environment.new }

  describe "#define" do
    it "adds a value to the symbol table" do
      expect(subject.lookup(:foo)).to be_nil
      subject.define(:foo, 1)
      expect(subject.lookup(:foo)).to eq(1)
    end

    it "overwrites existing values in the same scope" do
      subject.define(:foo, 1)
      subject.define(:foo, 2)
      expect(subject.lookup(:foo)).to eq(2)
    end

    it "preserves values in lower scopes" do
      subject.define(:foo, 1)
      subject.push
      subject.define(:foo, 2)
      subject.pop

      expect(subject.lookup(:foo)).to eq(1)
    end
  end

  describe "#lookup" do
    it "returns nil if the symbol does not exist" do
      expect(subject.lookup(:foo)).to be_nil
    end

    it "searches through all scopes" do
      subject.define(:foo, 1)
      subject.push
      subject.push

      expect(subject.lookup(:foo)).to eq(1)
    end

    it "permits shadowing" do
      subject.define(:foo, 1)
      subject.push
      subject.define(:foo, 2)

      expect(subject.lookup(:foo)).to eq(2)
    end
  end

  describe "#push" do
    it "preserves values in lower scopes" do
      subject.define(:foo, 1)
      subject.push

      expect(subject.lookup(:foo)).to eq(1)
    end
  end

  describe "#pop" do
    it "does nothing to the root scope" do
      subject.define(:foo, 1)
      subject.pop

      expect(subject.lookup(:foo)).to eq(1)
    end

    context "when in higher scopes" do
      before { subject.push }
      it "removes values in the scope" do
        subject.define(:foo, 1)
        subject.pop

        expect(subject.lookup(:foo)).to be_nil
      end
    end
  end
end
