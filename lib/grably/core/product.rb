require 'powerpack/string/format' # Adds format method
require 'powerpack/string/remove_prefix'
require_relative 'task'

require_relative 'product/file_ext'
require_relative 'product/rename'

module Grably
  module Core
    class Product
      # Class stub for future reference.
      # Main implementation goes below
    end

    # Set of predefined product filters, used by ProductExpand
    module ProductFilter
      # TODO: I'm pretty sure that someone would like to have set_no_extglob, set_no_dotmatch, set_no_pathname
      # TODO: as global methods for ProductFilter module
      GLOB_MATCH_MODE = File::FNM_EXTGLOB | File::FNM_DOTMATCH | File::FNM_PATHNAME
      # Generates lambda filter out of `String` with
      # glob pattern description
      def generate_glob_filter(glob)
        # Negative glob starts with '!'
        negative = glob.start_with?('!')
        # Strip leading '!' then
        glob.remove_prefix!('!') if negative
        lambda do |path|
          matches = File.fnmatch(glob, path, GLOB_MATCH_MODE)
          # inverse match if glob is negative
          matches = !matches if negative
          matches
        end
      end

      # Matches filter string
      FILTER_STRING_REGEXP = /^((((?<new_base>.+?)?:)?((?<old_base>.+?)?:))?)(?<glob>.+)$/
      # FILTER_STRING_REGEXP groups in fixed order.
      FILTER_STRING_GROUPS = %i(new_base old_base glob).freeze

      def generate_string_filter(filter_string)
        new_base, old_base, glob = parse_string_filter(filter_string)
        glob_filter = generate_glob_filter(glob)
        lambda do |products, _expand|
          filtered = filter_products(products, new_base, old_base) { |_src, dst, _meta| glob_filter.call(dst) }
          filtered.map { |src, dst, meta| Product.new(src, dst, meta) }
        end
      end

      def parse_string_filter(filter_string)
        # Here we need generate lambda for string filter
        parsed_filter = FILTER_STRING_REGEXP.match(filter_string) do |m|
          FILTER_STRING_GROUPS.map { |g| m[g] }
        end
        parsed_filter || raise('Filter \'%s\' doesn\'t match format'.format(filter_string))
      end

      def filter_products(products, new_base, old_base, &dst_filter)
        products
          .map { |p| [p.src, p.dst, p.meta] }
          .select { |_, dst, _| !old_base || File.fnmatch("#{old_base}/**/*", dst, GLOB_MATCH_MODE) }
          .map { |src, dst, meta| [src, dst.gsub(%r{^#{old_base.to_s}[/\\]}, ''), meta] }
          .select(&dst_filter)
          .map { |src, dst, meta| [src, new_base.nil? ? dst : File.join(new_base, dst), meta] }
      end
    end

    # Product expansion rules.
    # Expand is mapping from anything(almost) to list of products
    #
    # We have following expansion rules:
    #
    # * Symbol can represent following entities:
    #
    #   * `:task_deps` - all all backets from all task prerequisites
    #   * `:last_job` - result of last executed job
    #   * any other symbol - backet of task with that name
    #
    # * Hash describes mapping from product expandable expression to filter in form of `{ expr => filter }`.
    #   Filter can be either string or lambda (proc).
    #   * If filter is a String it can be:
    #     * glob pattern (`gN`)
    #     * negative glob pattern, e.g. `!` is prepended (`!gN`)
    #     * filter with substitution (can be in two forms):
    #     * `base:glob` - select every file starting with `base`, strip `base`
    #       from beginning, apply glob to the rest of path
    #     * `new_base:old_base:glob` - select every file starting with base,
    #       strip `old_base`, apply glob to the rest of path, add `new_base`
    #     Every operation is performed over Product `dst`, not `src`.
    #    `glob` means any glob (either simple glob or negative glob)
    #
    #   * If filter is `Proc`:
    #
    #     * this proc must have arity of 2
    #     * first argument is expanded expression `expr`
    #     * second argument is contexted expand function (which means it have proper task argument)
    #
    # * `Array` expansion is expanding each element
    #
    # * `String` expands as glob pattern
    #   If string is path to file, then it expands into single element array of products.
    #   Else (i.e. string is directory) it expands into array of products representing
    #   directory content.
    #
    # * {Grably::Core::Task} expands to its backet.
    #   Behaving strictly we can only get task backet of
    #   self, i.e. target_task == context_task, or if target_task is
    #   context_task prerequisite (direct or indirect).
    #
    # * Product expands to self
    module ProductExpand
      class << self
        include ProductFilter

        def expand(srcs, task_or_opts = nil, opts = {})
          # if task provided will use it as context
          if task_or_opts.is_a?(Hash)
            opts = task_or_opts.merge(opts)
          else
            task = task_or_opts
          end
          # Wrap o in Array to simplify processing flow
          srcs = [srcs] unless srcs.is_a? Array
          # First typed expand will be array expand. So we will get array as
          # result
          typed_expand(srcs, task, opts)
        end

        def expand_symbol(symbol, task, opts)
          case symbol
          when :task_deps
            typed_expand(task.prerequisites.map(&:to_sym), task, opts)
          else
            task_ref = Task[symbol]
            typed_expand(task_ref, task, opts)
          end
        end

        def expand_hash(hash, task, opts)
          hash.flat_map do |expr, filter|
            # If got string generate lambda representing filter operation
            filter = generate_string_filter(filter) if filter.is_a? String
            raise 'Filter is not a proc %s'.format(filter) unless filter.is_a?(Proc)
            filter.call(typed_expand(expr, task, opts), ->(o) { expand(o, task) })
          end
        end

        def expand_array(elements, task, opts)
          elements.flat_map { |e| typed_expand(e, task, opts) }
        end

        def expand_string(expr, _task, opts)
          base = opts[:base_dir] || Dir.pwd
          path = File.absolute_path(expr, base)
          unless File.exist?(path)
            warn "'#{expr}' does not exist. Can't expand path"
            return []
          end
          # Will expand recursively over directory content.
          File.directory?(path) ? expand_dir(expr, base) : Product.new(path)
        end

        def expand_proc(proc, task, opts)
          proc.call(->(o) { expand(o, task, opts) })
        end

        def expand_task(target_task, context_task, _opts)
          # Behaving strictly we can only get task backet of
          # self, i.e. target_task == context_task, or if target_task is
          # context_task prerequisite (direct or indirect).
          unless check_dependencies(target_task, context_task)
            raise(ArgumentError,
                  'Target task [%s] is not in context task [%s] prerequisites'
                      .format(target_task.name, context_task.name))
          end
          target_task.bucket
        end

        def expand_product(product, _, _)
          product
        end

        def expand_nil(_nil, _, _)
          []
        end

        # We define method table for expand rules.
        # Key is object class, value is method.
        #
        # Initially we just define set of Class to Symbol mappings. Then calling
        # ProductExpand.singleton_method on each method name.
        # As bonus following this technique we will get NameError
        # immediately after module load.
        METHOD_TABLE =
          Hash[*{
            Symbol => :expand_symbol,
            Hash => :expand_hash,
            Array => :expand_array,
            String => :expand_string,
            Proc => :expand_proc,
            Grably::Core::Task => :expand_task,
            Product => :expand_product,
            NilClass => :expand_nil
          }
          .flat_map { |k, v| [k, ProductExpand.singleton_method(v)] }]
          .freeze

        def typed_expand(element, task, opts)
          # Fetching expand rule for element type
          method_refs = METHOD_TABLE.select { |c, _| element.is_a?(c) }
          raise 'Multiple expands found for %s. Expands %s'.format(element, method_refs.keys) if method_refs.size > 1
          method_ref = method_refs.values.first
          unless method_ref
            err = 'No expand for type: %s. Element is \'%s\''
            raise err.format(element.class, element)
          end
          # Every expand_%something% method follows same contract, so we just
          # passing standard set of arguments
          method_ref.call(element, task, opts)
        end

        ## Utility methods

        # Ensure that target task is among context_task dependencies
        def check_dependencies(target_task, context_task)
          return true if target_task == context_task
          context_task.all_prerequisite_tasks.include?(target_task)
        end

        private

        def expand_dir(expr, base)
          glob = File.join(expr, '**/*')

          Dir.glob_base(glob, base)
             .select { |e| File.file?(File.absolute_path(e, base)) }
             .map { |file| Product.new(File.absolute_path(file, base), file.sub(expr + File::SEPARATOR, '')) }
        end
      end
    end

    # Product is core, minimal entity in build process.
    # It describes real file with virtual destination.
    # Product instances should be immutable.
    class Product
      include Grably::ProductFileExtensions
      include Grably::ProductRename
      attr_reader :src, :dst, :meta

      def initialize(src, dst = nil, meta = {})
        raise 'src should be a string' unless src.is_a?(String)
        raise 'dst should be a string' unless dst.is_a?(String) || dst.nil?
        @src = File.expand_path(src)
        @dst = dst || File.basename(src)
        @meta = meta.freeze # Ensure meta is immutable
      end

      def [](*keys)
        return @meta[keys.first] if keys.size == 1

        # Iterate over keys to preserve order so we can unpack result
        # like:
        # foo, bar = product[:foo, :bar]
        keys.map { |k| @meta[k] }
      end

      def update(values)
        # Provide immutable update
        Product.new(@src, @dst, @meta.merge(values))
      end

      def exist?
        File.exist?(@src)
      end

      def inspect
        'Product[src=\'%s\', dst=\'%s\', meta=%s]'.format(src, dst, meta)
      end

      def map
        src, dst, meta = yield(@src, @dst, @meta)
        Product.new(src || @src, dst || @dst, meta || @meta)
      end

      def to_s
        @src
      end

      def ==(other)
        # Everything which not a Product, can't be equal to Product
        return false unless other.is_a? Product

        # Should we include meta in comparison?
        @src.eql?(other.src) && @dst.eql?(other.dst)
      end

      def hash
        @src.hash
      end

      def eql?(other)
        self == other
      end

      def basename(*args)
        File.basename(@dst, *args)
      end

      # Including helper classes
      # Utility logic extracted from Product class to keep it clean and concise
      class << self
        # Expand expression according to ProductExpand rules
        # @param expr [Object] any expandable product expression
        # @param task [Symbol|Rake::Task] context task to expand expression
        # @param opts [Hash] additional options
        # @return [Array<Product>] flat list of expanded products
        def expand(expr, task = nil, opts = {})
          Grably::Core::ProductExpand.expand(expr, task, opts)
        end

        # Wrap expand expression with command wich adds provided meta to each
        # resulting product.
        # Note: this actualy not expands expression. Just wraps with another
        #       expression.
        # @param expr [Object] any expandable product expression
        # @param meta [Hash] hash of meta values
        # @return [Hash] product expand expression
        def with_meta(expr, meta = {})
          expand(expr).map { |p| p.update(meta) }
        end
      end
    end
  end
end
