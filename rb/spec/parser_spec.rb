require 'tok_helper'
require 'parse_helper'
require 'value_helper'
require 'parser'

RSpec.describe Parser do
  include TokHelper
  include ParseHelper
  include ValueHelper

  it "parses symbols" do
    expect(parser(tok(:SYM, :foo)).parse)
      .to eq(sym(:foo))
  end

  it "parses numbers" do
    expect(parser(tok(:NUM, 1)).parse)
      .to eq(int(1))
  end

  it "parses strings" do
    expect(parser(tok(:STR, "foo")).parse)
      .to eq(str("foo"))
  end

  it "parses s-expressions" do
    expect(parser(tok(:BRA), tok(:SYM, :foo), tok(:SYM, :bar), tok(:KET)).parse)
      .to eq(sexp(sym(:foo), sym(:bar)))
  end

  describe "quoting" do
    it "wraps symbols" do
      expect(parser(tok(:QUOT), tok(:SYM, :foo)).parse)
        .to eq(sexp(sym(:quote), sym(:foo)))
    end

    it "wraps s-expressions" do
      expect(parser(tok(:QUOT), tok(:BRA),
                    tok(:SYM, :foo), tok(:SYM, :bar),
                    tok(:KET)).parse)
        .to eq(sexp(sym(:quote), sexp(sym(:foo), sym(:bar))))
    end
  end

  it "parses nested s-expressions" do
    expr = parser(tok(:BRA),
                  tok(:BRA),
                  tok(:SYM, :foo), tok(:SYM, :bar),
                  tok(:KET),
                  tok(:SYM, :baz),
                  tok(:KET)
                 ).parse

    expect(expr).to eq(sexp(sexp(sym(:foo), sym(:bar)), sym(:baz)))
  end

  context "when given too little input" do
    it "throws an error" do
      expect { parser(tok(:BRA)).parse }
        .to raise_error(Parser::ParseError)
    end
  end

  context "when given mismatched brackets" do
    it "throws an error" do
      expect { parser(tok(:KET)).parse }
    end
  end

  describe "#done?" do
    context "when there are still tokens" do
      subject { parser(tok(:BRA)) }
      it { is_expected.not_to be_done }
    end

    context "when no tokens are left" do
      subject { parser }
      it { is_expected.to be_done }
    end
  end
end
