module Value
  Int   = Struct.new(:val)
  Sym   = Struct.new(:name)
  Fn    = Struct.new(:block)
  Macro = Struct.new(:block)

  Nil = Object.new
  Nil.extend(Enumerable)
  def Nil.each; end
  def Nil.to_a
    []
  end

  class Cons < Struct.new(:head, :tail)
    include Enumerable
    def each #+yields
      curr = self
      while curr.is_a? Cons
        yield curr.head
        curr = curr.tail
      end
    end

    def to_a
      enum_for(:each).to_a
    end
  end

  def self.to_sexp(list)
    list.reverse_each.reduce(Nil) do |rest, val|
      Cons[val, rest]
    end
  end

  def self.sexp?(val)
    val.is_a?(Cons) || val.equal?(Nil)
  end
end
