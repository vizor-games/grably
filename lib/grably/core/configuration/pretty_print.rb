require 'yaml'
require_relative '../colors'

module Grably
  module Core
    module Configuration # :nodoc:
      # rubocop:disable all
      class ConfigurationVisitor < Psych::Visitors::YAMLTree
        def visit_Symbol(o)
          visit_String(o.to_s)
        end
      end
      # rubocop:enable all

      def pretty_print
        visitor = ConfigurationVisitor.create
        visitor << to_h
        visitor.tree.yaml STDOUT, {}
      end
    end
  end
end
