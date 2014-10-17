# encoding: utf-8

module Synvert::Core
  # Action defines rewriter action, add, replace or remove code.
  class Rewriter::Action
    # Initialize an action.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param code {String] new code to add, replace or remove.
    def initialize(instance, code)
      @instance = instance
      @code = code
      @node = @instance.current_node
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
        "\n\n" + rewritten_source.split("\n").map { |line|
          indent(@node) + line
        }.join("\n")
      else
        "\n" + indent(@node) + rewritten_source
      end
    end

    # The rewritten source code.
    #
    # @return [String] rewritten source code.
    def rewritten_source
      @rewritten_source ||= @node.rewritten_source(@code)
    end

    # Compare actions by begin position.
    #
    # @param action [Synvert::Core::Rewriter::Action]
    # @return [Integer] -1, 0 or 1
    def <=>(action)
      self.begin_pos <=> action.begin_pos
    end
  end
end

