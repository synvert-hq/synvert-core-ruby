# frozen_string_literal: true

module Synvert::Core
  # Action defines rewriter action, add, replace or remove code.
  class Rewriter::Action
    DEFAULT_INDENT = 2

    # @!attribute [r] begin_pos
    #   @return [Integer] begin position
    # @!attribute [r] end_pos
    #   @return [Integer] end position
    attr_reader :begin_pos, :end_pos

    # Initialize an action.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param code [String] new code to add, replace or remove.
    def initialize(instance, code)
      @instance = instance
      @code = code
      @node = @instance.current_node
    end

    def process
      calculate_position
      self
    end

    # Line number of current node.
    #
    # @return [Integer] line number.
    def line
      @node.loc.expression.line
    end

    # The rewritten source code with proper indent.
    #
    # @return [String] rewritten code.
    def rewritten_code
      if rewritten_source.split("\n").length > 1
        "\n\n" + rewritten_source.split("\n").map { |line| indent(@node) + line }.join("\n")
      else
        "\n" + indent(@node) + rewritten_source
      end
    end

    protected

    # The rewritten source code.
    #
    # @return [String] rewritten source code.
    def rewritten_source
      @rewritten_source ||= @node.rewritten_source(@code)
    end

    def squeeze_spaces
      if file_source[@begin_pos - 1] == ' ' && file_source[@end_pos] == ' '
        @begin_pos = @begin_pos - 1
      end
    end

    def squeeze_lines
      lines = file_source.split("\n")
      begin_line = @node.loc.expression.first_line
      end_line = @node.loc.expression.last_line
      before_line_is_blank = begin_line == 1 || lines[begin_line - 2] == ''
      after_line_is_blank = lines[end_line] == ''

      if lines.length > 1 && before_line_is_blank && after_line_is_blank
        @end_pos = @end_pos + "\n".length
      end
    end

    def file_source
      @file_source ||= @instance.file_source
    end
  end
end
