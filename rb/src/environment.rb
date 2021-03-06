require 'error'

class Environment
  SymbolError = LangError.of_type "Symbol"

  def initialize
    @root = Scope[{}]
    @root.parent = @root
  end

  def define(sym, val)
    @root.map[sym] = val
  end

  def elaborate(kvps) #+yields
    push
    kvps.each do |k, v|
      define(k, v)
    end
    ret = yield; pop; ret
  end

  def lookup(sym)
    @root.each do |map|
      if map.has_key? sym
        return map[sym]
      end
    end
    raise SymbolError, "Undefined symbol `#{sym}`"
  end

  def update(sym, val)
    @root.each do |map|
      if map.has_key? sym
        return (map[sym] = val)
      end
    end
    raise SymbolError, "Undefined symbol `#{sym}`"
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
        break if curr.equal? curr.parent
        curr = curr.parent
      end
    end
  end
end
