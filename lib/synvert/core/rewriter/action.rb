# frozen_string_literal: true

module Synvert::Core
  # Action defines rewriter action, insert, replace or delete code.
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
    # @param code [String] new code to insert, replace or delete.
    def initialize(instance, code)
      @instance = instance
      @code = code
      @node = @instance.current_node
    end

    # Calculate begin and end positions, and return self.
    #
    # @return [Synvert::Core::Rewriter::Action] self
    def process
      calculate_position
      self
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

    # Calculate the begin the end positions.
    #
    # @abstract
    def calculate_position
      raise NotImplementedError, 'must be implemented by subclasses'
    end

    # The rewritten source code.
    #
    # @return [String] rewritten source code.
    def rewritten_source
      @rewritten_source ||= @node.rewritten_source(@code)
    end

    # Squeeze spaces from source code.
    def squeeze_spaces
      if file_source[@begin_pos - 1] == ' ' && file_source[@end_pos] == ' '
        @begin_pos -= 1
      end
    end

    # Squeeze empty lines from source code.
    def squeeze_lines
      lines = file_source.split("\n")
      begin_line = @node.loc.expression.first_line
      end_line = @node.loc.expression.last_line
      before_line_is_blank = begin_line == 1 || lines[begin_line - 2] == ''
      after_line_is_blank = lines[end_line] == ''

      if lines.length > 1 && before_line_is_blank && after_line_is_blank
        @end_pos += "\n".length
      end
    end

    # Remove unused comma.
    # e.g. `foobar(foo, bar)`, if we remove `foo`, the comma should also be removed,
    # the code should be changed to `foobar(bar)`.
    def remove_comma
      if ',' == file_source[@begin_pos - 1]
        @begin_pos -= 1
      elsif ', ' == file_source[@begin_pos - 2, 2]
        @begin_pos -= 2
      elsif ', ' == file_source[@end_pos, 2]
        @end_pos += 2
      elsif ',' == file_source[@end_pos]
        @end_pos += 1
      end
    end

    # Return file source.
    #
    # @return [String]
    def file_source
      @file_source ||= @instance.file_source
    end
  end
end
