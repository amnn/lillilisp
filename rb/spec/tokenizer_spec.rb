require 'tok_helper'
require 'tokenizer'

include TokHelper

def tok_test(input, tok, name = input)
  context "when fed #{name}" do
    subject { tokenize(input) }
    it "outputs #{name} token" do
      is_expected.to eq([tok])
    end
  end
end

RSpec.describe Tokenizer do
  tok_test("(",   tok(:BRA),       "open bracket")
  tok_test(")",   tok(:KET),       "close bracket")
  tok_test("'",   tok(:QUOT),      "quote")
  tok_test("&",   tok(:SYM, :&),   "rest indicator")
  tok_test("1",   tok(:NUM, 1),    "one")
  tok_test("+12", tok(:NUM, 12),   "positive number")
  tok_test("-23", tok(:NUM, -23),  "negative number")

  tok_test("foo", tok(:SYM, :foo), "symbol")
  tok_test("+",   tok(:SYM, :+),   "funky symbol")

  tok_test("my-var-name", tok(:SYM, :"my-var-name"), "kebab case")
  tok_test("var-1",       tok(:SYM, :"var-1"),       "symbol with number")

  tok_test("\"\"",          tok(:STR, ""),         "empty string")
  tok_test("\"foo\"",       tok(:STR, "foo"),      "string")
  tok_test("\"foo\\nbar\"", tok(:STR, "foo\nbar"), "string w/escaped character")
  tok_test("\"\\u000a\"",   tok(:STR, "\u000a"),   "string w/escaped code")

  describe "symbol" do
    it "is terminated by whitespace and comments" do
      expect(tokenize("hello wor;; comment\nld"))
        .to eq(sym_list(:hello, :wor, :ld))
    end

    it "is terminated by opening and closing brackets" do
      expect(tokenize("foo(bar)baz"))
        .to eq([tok(:SYM, :foo),
                tok(:BRA), tok(:SYM, :bar), tok(:KET),
                tok(:SYM, :baz)])
    end

    it "is termianted by the quote" do
      expect(tokenize("foo'bar"))
        .to eq([tok(:SYM, :foo), tok(:QUOT), tok(:SYM, :bar)])

    end
    it "is termianted by the rest parameter" do
      expect(tokenize("foo&bar"))
        .to eq([tok(:SYM, :foo), tok(:SYM, :&), tok(:SYM, :bar)])
    end
  end

  describe "sequences" do
    let(:toks) { sym_list(:foo, :bar) }

    it "brackets can appear immediately before or after another token" do
      expect(tokenize("(foo 1)"))
        .to eq([tok(:BRA), tok(:SYM, :foo), tok(:NUM, 1), tok(:KET)])

      expect(tokenize("(1 foo)"))
        .to eq([tok(:BRA), tok(:NUM, 1), tok(:SYM, :foo), tok(:KET)])
    end

    it "treats spaces as whitespace" do
      expect(tokenize("foo bar")).to eq(toks)
      expect(tokenize("foo\nbar")).to eq(toks)
    end

    it "treats commas as whitespace" do
      expect(tokenize("foo,bar")).to eq(toks)
    end
  end

  describe "comments" do
    let(:input)  { "foo ;; comment\n bar" }
    let(:output) { sym_list(:foo, :bar) }
    it "kills comments to the end of the line" do
      expect(tokenize(input)).to eq(output)
    end
  end
end
