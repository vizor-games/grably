module Grably
  module Core
    module TaskExtensions
      # Add expand method to Task
      module Expand
        # Expands expression in task context
        # @param expr [Object] expand expression
        # @return Array<Product> result of expand in task context
        def expand(expr)
          Product.expand(expr, self)
        end
      end
    end
  end
end
