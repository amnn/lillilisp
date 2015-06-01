module Value
  class Int < Struct.new(:val)
    def to_s
      val.to_s
    end
  end
end
