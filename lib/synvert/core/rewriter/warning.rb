# encoding: utf-8

module Synvert::Core
  # Warning is used to save warning message.
  class Rewriter::Warning
    # Initialize a warning.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param message [String] warning message.
    def initialize(instance, message)
      @instance = instance
      @message = message
    end

    # Warning message.
    #
    # @return [String] warning message.
    def message
      "#{@instance.current_file}##{line}: #{@message}"
    end

  private

    # Line number of current node.
    #
    # @return [Integer] line number.
    def line
      @instance.current_node.loc.expression.line
    end
  end
end
