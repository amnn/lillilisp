module Value
  class Str < Struct.new(:val)
    def to_s
      "\"#{val}\""
    end
  end
end
