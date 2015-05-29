require 'spec_helper'
require 'tok_helper'
require 'parse_helper'
require 'parser'

RSpec.describe Parser do
  it "parses symbols" do
    expect(parser(tok(:SYM, :foo)).parse)
      .to eq(ast(:SYM, :foo))
  end

  it "parses numbers" do
    expect(parser(tok(:NUM, 1)).parse)
      .to eq(ast(:NUM, 1))
  end

  it "parses s-expressions" do
    expect(parser(tok(:BRA), tok(:SYM, :foo), tok(:SYM, :bar), tok(:KET)).parse)
      .to eq(ast(:SEXP, [ast(:SYM, :foo), ast(:SYM, :bar)]))
  end

  it "parses nested s-expressions" do
    expr = parser(tok(:BRA),
                  tok(:BRA),
                  tok(:SYM, :foo), tok(:SYM, :bar),
                  tok(:KET),
                  tok(:SYM, :baz),
                  tok(:KET)
                 ).parse

    expect(expr).to eq(ast(:SEXP, [ast(:SEXP, [ast(:SYM, :foo),
                                               ast(:SYM, :bar)]),
                                   ast(:SYM, :baz)]))
  end

  context "when given too little input" do
    it "throws an error" do
      expect { parser(tok(:BRA)).parse }
        .to raise_error(ArgumentError)
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
