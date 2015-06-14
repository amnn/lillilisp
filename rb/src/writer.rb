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
      putln e
    end
  end

  class Req
    def initialize(proxy)
      @proxy = proxy
    end

    def ret(s)
      putln "~~> #{s}"
    end

    def method_missing(method, *args, &blk)
      @proxy.send(method, *args, &blk)
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
