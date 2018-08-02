module Grably
  module Core
    module TaskExtensions
      # # Bucket
      # Bucket keeps result of task execution
      module Bucket
        # Updates bucket with result of argument expand
        # @see [Grably::Core::ProductExpand]
        # @param product_expr
        # @return [Task]
        def <<(product_expr)
          expand = Product.expand(product_expr, self)
          ensure_bucket
          @bucket += expand

          self # Allow chaining calls like
        end

        def bucket
          ensure_bucket
        end

        def ensure_bucket
          @bucket ||= []
        end
      end
    end
  end
end
