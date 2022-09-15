# frozen_string_literal: true

module Synvert::Core
  # QueryScope finds out nodes by using node query language, then changes its scope to matching node.
  class Rewriter::QueryScope < Rewriter::Scope
    # Initialize a QueryScope.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param nql [String]
    # @param options [Hash]
    # @yield run on all matching nodes
    def initialize(instance, nql, options = {}, &block)
      super(instance, &block)

      @options = { including_self: true, stop_at_first_match: false, recursive: true }.merge(options)
      @node_query = NodeQuery.new(nql)
    end

    # Find out the matching nodes.
    #
    # It checks the current node and iterates all child nodes,
    # then run the block code on each matching node.
    # @raise [Synvert::Core::NodeQuery::Compiler::ParseError] if the query string is invalid.
    def process
      current_node = @instance.current_node
      return unless current_node

      matching_nodes = @node_query.query_nodes(current_node, @options)
      @instance.process_with_node(current_node) do
        matching_nodes.each do |node|
          @instance.process_with_node(node) do
            @instance.instance_eval(&@block)
          end
        end
      end
    end
  end
end
