
require 'set'

require 'lib/act/bdr.rb'

module Act
  class JavaBuilder < Builder
    def initialize
      #@flags = params[:flags] || []
    end

    def compile(filename, srcdir, classdir)
      cmd = "javac #{filename} -sourcepath #{srcdir} -d #{classdir}"
      puts cmd
      system(cmd)
      :completed
    end

    def jar(jarname, srcdir, classdir)
      sources = Dir.glob(File.join(srcdir, '**', '*.java'))
      depends_on, depended_on = build_dependency_maps(sources)
      to_compile = Set.new
      sources.each do |src|
        unless to_compile.include?(src)
          hash = hash_file(src)
          memo = MemoManager.instance.memo(src)
          unless memo.hash.eql?(hash)
            puts "#{src} needs to be recompiled"
            to_compile.add(src)
            src_pkg_name = src[(srcdir.length+1)...(src.length-5)].gsub(/\//, '.')
            deps = depended_on[src_pkg_name]
            unless deps == nil
              deps.each do |d| 
                puts "#{d} must be compiled as well"
                to_compile.add(src)
              end
            end
          end
        end
      end

      to_compile.each do |src|
        compile_lambda = lambda { compile(src, srcdir, classdir) }
        task = compile_task(src, compile_lambda)
        TaskManager.instance.give(task)
      end
      # Create compile tasks
      #build_and_memoize_dependency_maps(sources)
      #puts sources.join(',')
      #compile_tasks = sources.each do |src|
      #  dependencies(src)
      #  compile_lambda = lambda { compile(src, srcdir, classdir) }
      #  task = compile_task(src, compile_lambda)
      #  TaskManager.instance.give(task)
      #  task
      #end
    end

    def build_dependency_maps(sources)
      # file -> depends
      depends_on = Hash.new
      sources.each do |src| 
        depends_on[src] = dependencies(src)
        #puts "on: #{src} -> #{depends_on[src].to_a.join(',')}"
      end

      # depends -> file
      depended_on = Hash.new
      depends_on.each do |src,depends|
        depends.each do |d|
          if d.class == String # TODO: better check
            unless depended_on.has_key? d
              depended_on[d] = Set.new
            end
            depended_on[d].add(src)
            #puts "by: #{d} -> #{src}"
          end
        end
      end

      return depends_on, depended_on
    end

    @@IMPORT_REGEX = Regexp.new(/\Aimport ([a-zA-Z0-9_\.]+\*?)/)
    #@@IMPORT_REGEX = /\Aimport (.*)/
    def dependencies(filename)
      depends = Set.new
      File.open(filename, 'r') do |file|
        file.each do |line|
          if m = @@IMPORT_REGEX.match(line.chomp)
            import = m[1]
            if import.end_with? '*'
              import = import.gsub(/\./, '\\.').gsub(/\*/, '.*')
              depends.add(Regexp.new(import))
            else
              depends.add(import)
            end
          end
        end
      end
      depends
    end
  end

  #class DependencyCatalog
  #  def initialize(sources)
  #    @ = Hash.new
  #  end
#
#    def add(source, import)
#      dependants = @depended_on[import]
#      if dependants == nil
#        dependants = []
#      end
#      dependants.add(import)
#    end
#  end
end

