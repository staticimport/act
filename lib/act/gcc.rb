
require 'digest/sha2'

require 'lib/act/bdr.rb'
require 'lib/act/memo.rb'

module Act
  class GccBuilder < Builder
    def initialize(params = {})
      extras = params[:misc] || []
      includes = params[:include] || []
      lib_dirs = params[:libdir] || []
      libs = params[:lib] || []
      warns = params[:warn] || []
      @compile_flags = "#{extras.map{ |x| "-#{x}" }.join(' ')} " +
                       "#{warns.map{ |x| "-W#{x}" }.join(' ')} " +
                       "#{includes.map{ |x| "-I#{x}" }.join(' ')}"
      #@link_flags = "#{lib_dirs.map{ |x| "-L#{x}" }.join(' ')} " +
      #              "#{libs.map{ |x| "-l#{x}" }.join(' ')}"
      @link_flags = lib_dirs.map{|x| "-L#{x}"} +
                    libs.map{|x| "-l#{x}"}
    end

    def compile(filename, output_filename, compile_only = TRUE, extra_flags = [])
      # Determine compiler to use
      suffix = filename.match(/\.([^\.]+)$/)[1]
      case suffix
      when 'c', 'm'
        compiler = 'gcc'
      when 'cc', 'cp', 'cxx', 'cpp', 'CPP', 'c++', 'C'
        compiler = 'g++'
      else
        puts "act: Unexpected filename type: #{filename}"
        return :failed
      end

      # Compile!
      cmd = "#{compiler} #{@compile_flags} #{extra_flags.join(' ')} "
      if compile_only
        cmd += "-c "
      end
      cmd += "#{filename} -o #{output_filename}"
      puts cmd
      system(cmd)

      # Return proper status
      if $? != nil and $?.exitstatus == 0 then :completed else :failed end
    end

    def executable(source, output, params = {})
      #lib_dirs = params[:libdir] || []
      #libs = params[:lib] || []
      #flags = @lib_dirs.map{ |dir| "-L#{dir}" }.concat(@libs.map{ |lib| "-L#{lib}" })
      compile_task(source, lambda { compile(source, output, false, @link_flags) })
    end

    def static_lib(libname, sources, src_to_outdir)
      # Create output filenames and compile tasks
      compile_outputs = []
      compile_tasks = sources.map do |src|
        output_dir = "#{src_to_outdir.call(src)}"
        FileUtils.mkdir_p(output_dir)
        output_filename = "#{output_dir}/#{File.basename(src).sub(/\.[^.]+$/,'.o')}"
        compile_outputs.push output_filename
        compile_task(src, lambda { compile(src, output_filename) })
      end

      # Create static library task
      lib_task = Task.new do
        completed = compile_tasks.select { |t| t.state == :completed }
        unless completed.empty? and File.exists?(libname)
          cmd = "ar rcs #{libname} #{compile_outputs.join(' ')}"
          puts cmd
          system(cmd)
          if $? != nil and $?.exitstatus == 0 then :completed else :failed end
        else
          :nothing_to_do
        end
      end
      MemoManager.instance.memo(libname).output.add(libname)
      lib_task.depends.merge(compile_tasks)
      lib_task
    end
  end
end

