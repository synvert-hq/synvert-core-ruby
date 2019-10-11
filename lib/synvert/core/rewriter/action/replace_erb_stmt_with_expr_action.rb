# encoding: utf-8

module Synvert::Core
  # ReplaceErbStmtWithExprAction to replace erb stmt code to expr,
  #   e.g. <% form_for ... %> => <%= form_for ... %>.
  class Rewriter::ReplaceErbStmtWithExprAction < Rewriter::Action
    def initialize(instance, code = nil)
      super
    end

    # Begin position of code to replace.
    #
    # @return [Integer] begin position.
    def begin_pos
      node_begin_pos = @node.loc.expression.begin_pos
       while @node.loc.expression.source_buffer.source[node_begin_pos -= 1] == ' '
      node_begin_pos - Engine::ERUBY_STMT_SPLITTER.length + 1
    end

    # End position of code to replace.
    #
    # @return [Integer] end position.
    def end_pos
      node_begin_pos = @node.loc.expression.begin_pos
      node_begin_pos += @node.loc.expression.source.index 'do'
       while @node.loc.expression.source_buffer.source[node_begin_pos += 1] != '@'
      node_begin_pos
    end

    # The rewritten erb expr code.
    #
    # @return [String] rewritten code.
    def rewritten_code
      @node.loc.expression.source_buffer.source[begin_pos...end_pos].sub(
        Engine::ERUBY_STMT_SPLITTER,
        '@output_buffer.append= '
      )
        .sub(Engine::ERUBY_STMT_SPLITTER, Engine::ERUBY_EXPR_SPLITTER)
    end
  end
end
