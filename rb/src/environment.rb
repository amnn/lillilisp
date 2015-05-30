class Environment
  class SymbolError < StandardError; end

  def initialize
    @root = Scope[{}]
    @root.parent = @root
  end

  def define(sym, val)
    @root.map[sym] = val
  end

  def lookup(sym)
    @root.each do |map|
      if map.has_key? sym
        return map[sym]
      end
    end
    raise SymbolError, "No value for symbol >>> #{sym} <<<"
  end

  def push
    @root = Scope[{}, @root]
  end

  def pop
    @root = @root.parent
  end

  private
  class Scope < Struct.new(:map, :parent)
    include Enumerable

    def each #+yields
      curr = self
      loop do
        yield curr.map
        break if curr == curr.parent
        curr = curr.parent
      end
    end
  end
end
