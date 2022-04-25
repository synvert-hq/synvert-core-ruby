# frozen_string_literal: true

module Synvert::Core
  # QueryScope finds out nodes by using node query language, then changes its scope to matching node.
  class Rewriter::QueryScope < Rewriter::Scope
    # Initialize a QueryScope.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param query_string [String]
    # @yield run on all matching nodes
    def initialize(instance, query_string, &block)
      super(instance, &block)
      @query_string = query_string
    end

    # Find out the matching nodes.
    #
    # It checks the current node and iterates all child nodes,
    # then run the block code on each matching node.
    # @raise [Synvert::Core::NodeQuery::Compiler::ParseError] if the query string is invalid.
    def process
      current_node = @instance.current_node
      return unless current_node

      @instance.process_with_node(current_node) do
        NodeQuery::Parser.new.parse(@query_string).query_nodes(current_node).each do |node|
          @instance.process_with_node(node) do
            @instance.instance_eval(&@block)
          end
        end
      end
    rescue NodeQuery::Lexer::ScanError, Racc::ParseError => e
      raise NodeQuery::Compiler::ParseError, "Invalid query string: #{@query_string}"
    end
  end
end
