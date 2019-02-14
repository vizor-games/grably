require 'rake/tasklib'

module Grably
  module Java
    class Project < Rake::TaskLib
      def initialize(&block)
        @srcs = []
        @res = []
        @libs = []

        if block_given?
          instance_exec(&block)
        else
          load_defaults
        end

        generate_tasks
      end

      def src(dirs, scope: :compile)
        @srcs << [dirs, { scope: scope }]
      end

      def lib(name, scope: :compile)
        @libs << [name, { scope: scope }]
      end

      def res(dirs, scope: :compile)
        @res << [dirs, { scope: scope }]
      end

      def main(class_name)
        @main_class = class_name
      end

      private

      def load_defaults
        # TBD
      end

      def sources(opts)
        fetch(@srcs, opts)
      end

      def libs(opts)
        fetch(@libs, opts)
      end

      def resources(opts)
        fetch(@res, opts)
      end

      def fetch(list, opts)
        list.select { |_, o| contains?(o, opts) }.map(&:first)
      end

      def contains?(this, other)
        (other.to_a - this.to_a).empty?
      end

      def scan_deps(targets)
        targets.select { |x| x.is_a?(Symbol) }
      end

      def generate_tasks
        src = sources(scope: :compile)
        lib = libs(scope: :compile)
        res = resources(scope: :compile)

        generate_build(src, lib, res)

        src_test = sources(scope: :test)
        lib_test = libs(scop: :test)
        res_test = res(scope: :compile)

        generate_test(src_test, lib_test, res_test)
      end

      def generate_build(src, lib, res)
        task(deps: scan_deps(lib)) do |_t|
          puts 'Fetching libs:'

          lib.each { |l| puts l }
        end

        task compile: %i(deps) do |t|
          t << t.javac(src, libs: :deps)
        end

        task jar: %i(compile) + scan_deps(res) do |t|
          t << t.jar([:compile, res], File.basename(Dir.pwd) + '.jar')
        end
      end

      def generate_test(src, lib, res)
      end
    end
  end
end
