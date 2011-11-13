
require 'set'
require 'singleton'
require 'thread'

module Act
  class Task
    attr_accessor :depends, :state
    def initialize(&command)
      @command = command
      @depends = Set.new
      @state = :pending
    end
    def execute
      @state = @command.call
    end
  end

  class TaskManager
    include Singleton

    def initialize
      @mutex = Mutex.new
      @state = :live
      @tasks = []
    end
    def give(task)
      if task == nil
        raise "Nil task given!"
      end
      @mutex.synchronize do
        @tasks.push task
      end
    end
    def process(num_threads)
      threads = []
      num_threads.times do |x|
        threads.push(Thread.new do
          task = TaskManager.instance.take
          until task == nil
            task.execute
            if task.state == :failed
                @state = :failed
            end
            task = TaskManager.instance.take(task)
          end
        end)
      end
      threads.each do |thread| thread.join end
    end
    def take(finished_task=nil)
      while @state == :live
        @mutex.synchronize do
          # remove finished_task from remaining tasks' dependencies
          unless finished_task == nil
            @tasks.each do |task|
              task.depends.delete finished_task
            end
            finished_task = nil
          end

          # find task ready to run
          unless @tasks.empty?
            (0...@tasks.length).each do |index|
              task = @tasks[index]
              if task.depends.empty?
                @tasks.delete_at index
                return task
              end
            end
            #sleep 0.01 # TODO: this is crap
          else
            return nil
          end
        end
      end
    end
  end
end

