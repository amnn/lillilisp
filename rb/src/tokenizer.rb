class Tokenizer
  include Enumerable

  class Token < Struct.new(:type, :val)
    def to_s
      type.to_s + (val ? "[#{val}]" : "")
    end
  end

  def self.stream(input)
    Tokenizer.new(input).enum_for(:each)
  end

  def initialize(input)
    @input = input
  end

  def each # yields
    until @input.empty?
      case @input
      when /\A(\s|,)/
        @input.slice!(/\A[\s,]+/)
      when /\A;/
        @input.slice!(/\A.*$/)
      when /\A\(/
        @input.slice!(0)
        yield Token[:BRA]
      when /\A\)/
        @input.slice!(0)
        yield Token[:KET]
      when /\A\'/
        @input.slice!(0)
        yield Token[:QUOT]
      when /\A\&/
        @input.slice!(0)
        yield Token[:SYM, :&]
      when /\A\"/
        str = @input
          .slice!(/\A(?:\".*[^\\]\")|\"\"/)[1...-1]
          .gsub(/\\u[a-f\d]{4}/) { |m| unescape(m[1..-1]) }
          .gsub(/\\./) { |m| unescape(m[1..-1]) }
        yield Token[:STR, str]
      when /\A[+-]?[0-9]/
        num = @input.slice!(/\A[+-]?[0-9][0-9_]*/).to_i
        yield Token[:NUM, num]
      else
        sym = @input.slice!(/\A.[^\s,;()'&]*/i).to_sym
        yield Token[:SYM, sym]
      end
    end
  end

  private
  UNESCAPE_CODES = {
    '0'  => "\u0000",
    'a'  => "\u0007",
    'b'  => "\u0008",
    't'  => "\u0009",
    'n'  => "\u000a",
    'v'  => "\u000b",
    'f'  => "\u000c",
    'r'  => "\u000d",
    '"'  => "\u0027",
    '\\' => "\u002f",
    "'"  => "\u005c",
  }

  def unescape(code)
    if code[0] == 'u'
      [code[1..-1].hex].pack('U')
    else
      UNESCAPE_CODES[code[0]] || code.first
    end
  end
end
