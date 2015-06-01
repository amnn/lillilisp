class LangError < StandardError
  class << self
    def of_type(name)
      Class.new(LangError) do
        define_method(:name) { name }
      end
    end
  end

  def to_s
    "#{name} Error: #{super.to_s}"
  end
end
