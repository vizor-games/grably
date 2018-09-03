module Grably # :nodoc:
  class JavacJob # :nodoc:
    include Grably::Job
    include Grably::Java
    include FileUtils

    srcs :srcs
    srcs :libs
    srcs :classes
    opt :ext
    opt :target
    opt :source
    opt :debug

    def setup(srcs, p = {})
      p = p.clone
      @srcs = { srcs => '**/*.java' }
      @libs = p.delete(:libs) || :task_deps
      @classes = p.delete(:classes)
      @ext = p.delete(:opts)
      @target = p.delete(:target) # target is intended to be global across single project
      @source = p.delete(:source)
      @debug = p.delete(:debug) # nil means no any option for javac

      raise "unsupported parameters: #{p.inspect}" unless p.empty?
    end
  end

  def build # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    log_msg "Compiling #{@srcs.size} classes"

    classed_dir = job_path('classes')
    out_dir = job_path('out')

    # # Make free dir in order to skip unnecessary recompiling for jar sources
    # srcs_dir = job_path('srcs')
    # mkdir_p(srcs_dir)

    classpath = @libs.clone
    unless @classes.nil?
      ln(@classes, classed_dir)
      classpath << classed_dir
    end

    args = [@ext]

    unless @debug.nil?
      args << '-g:none' unless @debug
      args << '-g' if @debug
    end

    args += ['-d', out_dir]
    args += ['-classpath', classpath.join(File::PATH_SEPARATOR)] unless classpath.empty?
    #args += ['-sourcepath', srcs_dir]
    args += @srcs.map(&:to_s)

    args_file = job_path('args-file')
    File.open(args_file, 'w') do |f|
      args.flatten.compact.each { |a| f.puts a.to_s }
    end
    args = "@#{args_file}"

    mkdir_p(out_dir)
    [javac_cmd(target: @target, source: @source), args].run { |l| puts "  #{l}" }

    { out_dir => '**/*' }
  end
end
