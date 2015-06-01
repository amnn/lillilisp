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
        eat_ws
      when /\A;/
        eat_line
      when /\A\(/
        eat; yield Token[:BRA]
      when /\A\)/
        eat; yield Token[:KET]
      when /\A\'/
        eat; yield Token[:QUOT]
      when /\A\&/
        eat; yield Token[:SYM, :&]
      when /\A\"/
        yield Token[:STR, slice_str]
      when /\A[+-]?[0-9]/
        yield Token[:NUM, slice_num]
      else
        yield Token[:SYM, slice_sym]
      end
    end
  end

  private
  SYMBOL_TERMINATORS = %w{\s , ; ( ) ' & "}

  def eat
    @input.slice!(0)
  end

  def eat_ws
    @input.slice!(/\A[\s,]+/)
  end

  def eat_line
    @input.slice!(/\A.*$/)
  end

  def slice_str
    desanitize @input.slice!(/\A(?:\".*[^\\]\")|\"\"/)[1...-1]
  end

  def slice_num
    @input.slice!(/\A[+-]?[0-9][0-9_]*/).to_i
  end

  def slice_sym
    @input.slice!(/\A.[^#{SYMBOL_TERMINATORS.join}]*/i).to_sym
  end

  def desanitize(input)
    input
      .gsub(/\\u[a-f\d]{4}/) { |m| unescape(m[1..-1]) }
      .gsub(/\\./) { |m| unescape(m[1..-1]) }
  end

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
