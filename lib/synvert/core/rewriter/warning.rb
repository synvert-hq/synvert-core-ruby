# frozen_string_literal: true

module Synvert::Core
  # Warning is used to save warning message.
  class Rewriter::Warning
    # Initialize a Warning.
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param message [String] warning message.
    def initialize(instance, message)
      @file_path = instance.current_file
      @line = instance.current_node.loc.expression.line
      @message = message
    end

    # Warning message.
    #
    # @return [String] warning message.
    def message
      "#{@file_path}##{@line}: #{@message}"
    end
  end
end
