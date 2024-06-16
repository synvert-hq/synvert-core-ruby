# frozen_string_literal: true

module Synvert::Core
  # Warning is used to save warning message.
  class Rewriter::Warning
    # Initialize a Warning.
    #
    # @param file_path [String] file path.
    # @param line [Integer] file line.
    # @param message [String] warning message.
    def initialize(file_path, line, message)
      @file_path = file_path
      @line = line
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
