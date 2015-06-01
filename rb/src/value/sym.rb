module Value
  class Sym < Struct.new(:name)
    def to_s
      name.to_s
    end
  end
end
