module Value
  Int  = Struct.new(:val)
  Sym  = Struct.new(:name)
  Cons = Struct.new(:head, :tail)
  Fn   = Struct.new(:env, :block)

  Nil  = Object.new

  def self.sexp(list)
    list.reverse_each.reduce(Nil) do |rest, val|
      Cons[val, rest]
    end
  end
end
