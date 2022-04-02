# frozen_string_literal: true

module Synvert::Core
  # Synvert global configuration.
  class Configuration
    class << self
      # @!attribute [w] path
      # @!attribute [w] skip_files
      # @!attribute [w] show_run_process
      attr_writer :path, :skip_files, :show_run_process

      # Get the path.
      #
      # @return [String] default is '.'
      def path
        @path || '.'
      end

      # Get a list of skip files.
      #
      # @return [Array<String>] default is [].
      def skip_files
        @skip_files || []
      end

      # Check if show run process.
      #
      # @return [Boolean] default is false
      def show_run_process
        @show_run_process || false
      end
    end
  end
end
