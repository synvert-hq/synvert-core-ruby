# frozen_string_literal: true

module Synvert::Core
  # ReplaceErbStmtWithExprAction to replace erb stmt code to expr,
  # @example
  #   e.g. <% form_for ... %> => <%= form_for ... %>.
  class Rewriter::ReplaceErbStmtWithExprAction < NodeMutation::Action
    # Initialize a ReplaceErbStmtWithExprAction.
    #
    # @param node [Synvert::Core::Rewriter::Node]
    def initialize(node, erb_source)
      super(node, nil)
      @erb_source = erb_source
    end

    # The new erb expr code.
    #
    # @return [String] new code.
    def new_code
      '='
    end

    private

    # Calculate the begin the end positions.
    def calculate_position
      @start = NodeMutation.adapter.get_start(@node)
      loop do
        @start -= 1
        break if @erb_source[@start] == '%'
      end
      @start += 1
      @end = @start
    end
  end
end
