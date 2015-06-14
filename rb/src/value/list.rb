module Value
  Nil = Object.new
  Nil.extend(Enumerable)
  def Nil.each; end
  def Nil.to_a
    []
  end

  def Nil.to_s
    "'()"
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

    def to_s
      if Value.nil_terminated?(self)
        "'(#{enum_for(:each).to_a.join(' ')})"
      else
        "'(#{head} . #{tail})"
      end
    end
  end


  module ListHelpers
    def to_sexp(list, term = Nil)
      list.reverse_each.reduce(term) do |rest, val|
        Cons[val, rest]
      end
    end

    def sexp?(val)
      val.is_a?(Cons) || val.equal?(Nil)
    end

    def nil_terminated?(list)
      loop do
        case list
        when Nil
          return true
        when Cons
          list = list.tail
        else
          return false
        end
      end
    end
  end
end
