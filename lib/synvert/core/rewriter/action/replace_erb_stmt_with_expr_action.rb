# frozen_string_literal: true

module Synvert::Core
  # ReplaceErbStmtWithExprAction to replace erb stmt code to expr,
  # @example
  #   e.g. <% form_for ... %> => <%= form_for ... %>.
  class Rewriter::ReplaceErbStmtWithExprAction < NodeMutation::Action
    # Initialize a ReplaceErbStmtWithExprAction.
    #
    # @param node [Synvert::Core::Rewriter::Node]
    def initialize(node)
      super(node, nil)
    end

    # The new erb expr code.
    #
    # @return [String] new code.
    def new_code
      NodeMutation.adapter.file_content(@node)[@start...@end]
        .sub(Engine::ERUBY_STMT_SPLITTER, '@output_buffer.append= ')
        .sub(Engine::ERUBY_STMT_SPLITTER, Engine::ERUBY_EXPR_SPLITTER)
    end

    private

    # Calculate the begin the end positions.
    def calculate_position
      node_start = NodeMutation.adapter.get_start(@node)
      node_source = NodeMutation.adapter.get_source(@node)
      file_content = NodeMutation.adapter.file_content(@node)

      whitespace_index = node_start
      while file_content[whitespace_index -= 1] == ' '
      end
      @start = whitespace_index - Engine::ERUBY_STMT_SPLITTER.length + 1

      at_index = node_start + node_source.index('do')
      while file_content[at_index += 1] != '@'
      end
      @end = at_index
    end
  end
end
