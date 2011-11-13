
require 'fileutils'
require 'lib/act/task.rb'

module Act
  class Builder
    def compile_task(filename, compile_lambda)
      Act::Task.new do
        hash = hash_file(filename)
        memo = MemoManager.instance.memo(filename)
        unless memo.hash.eql?(hash)
          #dir = File.dirname(output_filename)
          #unless File.exists?(dir)
          #  Dir.mkdir(dir)
          #end
          status, output_filenames = compile_lambda.call
          if status == :completed
            #output_filename.each { |f| memo.output.add f }
            memo.hash = hash
          end
          status
        else
          :nothing_to_do
        end
      end
    end

    def copy(filenames, depend_tasks, copy_filename_lambda)
      task = Act::Task.new do
        status = :completed

        filenames.each do |filename|
       	  hash = hash_file(filename)
          memo = MemoManager.instance.memo(filename)
          copy = copy_filename_lambda.call(filename)
          unless memo.hash.eql?(hash) and File.exists?(copy)
            copy_dir = File.dirname(copy)
            unless File.exists?(copy_dir)
              Dir.mkdir(copy_dir)
            end
            begin
              FileUtils.copy(filename, copy)
              memo.output.add copy
              memo.hash = hash
              puts "Copied #{filename} to #{copy}"
            rescue
              puts $!
              status = :failed
              break
            end
          end
          status
        end
      end
      task.depends.merge(depend_tasks)
      TaskManager.instance.give(task)
      task
    end

    def hash_file(filename)
      (Digest::SHA2.new << IO.read(filename)).to_s
    end
  end
end

