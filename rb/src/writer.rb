module Writer
  class Abs
    def putln(s = "")
      put(s)
      put("\n")
    end
  end

  class Std < Abs
    def put(s)
      print s.to_s
    end

    def ret(s)
      putln "--> #{s}"
    end

    def err(e)
      put e
    end
  end

  class Req < Std
    def ret(s)
      putln "~~> #{s}"
    end
  end

  class Null < Abs
    def put(s); end
    def ret(s); end
    def err(e)
      puts e
    end
  end
end
