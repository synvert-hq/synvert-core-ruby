# frozen_string_literal: true

module Synvert::Core
  # ReplaceErbStmtWithExprAction to replace erb stmt code to expr,
  #   e.g. <% form_for ... %> => <%= form_for ... %>.
  class Rewriter::ReplaceErbStmtWithExprAction < Rewriter::Action
    def initialize(instance, code = nil)
      super
    end

    def calculate_position
      node_begin_pos = @node.loc.expression.begin_pos
      while @node.loc.expression.source_buffer.source[node_begin_pos -= 1] == ' '
      end
      @begin_pos = node_begin_pos - Engine::ERUBY_STMT_SPLITTER.length + 1

      node_begin_pos = @node.loc.expression.begin_pos
      node_begin_pos += @node.loc.expression.source.index 'do'
      while @node.loc.expression.source_buffer.source[node_begin_pos += 1] != '@'
      end
      @end_pos = node_begin_pos
    end

    # The rewritten erb expr code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      @node.loc.expression.source_buffer.source[begin_pos...end_pos]
        .sub(Engine::ERUBY_STMT_SPLITTER, '@output_buffer.append= ')
        .sub(Engine::ERUBY_STMT_SPLITTER, Engine::ERUBY_EXPR_SPLITTER)
    end
  end
end
