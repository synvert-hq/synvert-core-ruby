# frozen_string_literal: true

module Synvert::Core
  # WithinScope finds out nodes which match nql or rules, then changes its scope to matching node.
  class Rewriter::WithinScope < Rewriter::Scope
    # Initialize a WithinScope.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param nql_or_rules [String|Hash]
    # @param options [Hash]
    # @yield run on all matching nodes
    # @raise [Synvert::Core::NodeQuery::Compiler::ParseError] if the query string is invalid.
    def initialize(instance, nql_or_rules, options = {}, &block)
      super(instance, &block)

      @options = { including_self: true, stop_at_first_match: false, recursive: true }.merge(options)
      @node_query = NodeQuery.new(nql_or_rules)
    end

    # Find out the matching nodes.
    #
    # It checks the current node and iterates all child nodes,
    # then run the block code on each matching node.
    def process
      current_node = @instance.current_node
      return unless current_node

      matching_nodes = @node_query.query_nodes(current_node, @options)
      @instance.process_with_node current_node do
        matching_nodes.each do |matching_node|
          @instance.process_with_node matching_node do
            @instance.instance_eval(&@block)
          end
        end
      end
    end
  end
end
