require 'error'

module Reader
  class Std
    def get
      gets || ""
    end
  end

  class File
    FileError = LangError.of_type "File"

    def initialize(fn)
      @fn = fn
    end

    def get
      ::File.open(@fn) { |f| f.read }
    rescue Errno::ENOENT
      raise FileError, "No such file, `#{fn}`"
    end
  end
end
