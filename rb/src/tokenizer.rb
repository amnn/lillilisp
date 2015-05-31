class Tokenizer
  include Enumerable

  Token = Struct.new(:type, :val)

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
      when /\A[+-]?[0-9]/
        num = @input.slice!(/\A[+-]?[0-9][0-9_]*/).to_i
        yield Token[:NUM, num]
      else
        sym = @input.slice!(/\A.[^\s,;()'&]*/i).to_sym
        yield Token[:SYM, sym]
      end
    end
  end
end
