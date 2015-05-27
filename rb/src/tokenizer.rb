class Tokenizer
  include Enumerable

  Token = Struct.new(:type, :val)

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
        yield Token[:BRA, nil]
      when /\A\)/
        @input.slice!(0)
        yield Token[:KET, nil]
      when /\A[+-]?[0-9]/
        yield Token[:NUM, @input.slice!(/\A[+-]?[0-9][0-9_]*/).to_i]
      else
        yield Token[:SYM, @input.slice!(/\A.[^\s,;]*/i).to_sym]
      end
    end
  end
end
