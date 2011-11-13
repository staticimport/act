
require 'set'
require 'singleton'

module Act
  class Memo
    attr_accessor :hash, :output, :timestamp

    def initialize
      @hash = ''
      @output = Set.new
      @timestamp = 0
    end
  end

  class MemoManager
    include Singleton

    def initialize
      if File.exists?(".act/memos")
        File.open(".act/memos", "r") do |file|
          @memos = Marshal.load(file)
        end
      else
        @memos = { }
      end
    end

    def delete_all_output
      @memos.each do |name,memo|
        memo.output.each do |out| 
          if File.exists?(out)
            puts "rm #{out}"
            File.delete(out)
          end
        end
        memo.hash = ''
        memo.timestamp = 0
      end
    end

    def memo(name)
      m = @memos[name]
      unless m
        m = Memo.new
        @memos[name] = m
      end
      m
    end

    def persist
      unless File.exists?('.act')
        Dir.mkdir('.act')
      end
      File.open(".act/memos", "w") do |file|
        Marshal.dump(@memos, file)
      end
    end
  end
end


