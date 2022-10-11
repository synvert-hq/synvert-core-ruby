# frozen_string_literal: true

module Synvert::Core
  # Synvert global configuration.
  class Configuration
    class << self
      # @!attribute [w] root_path
      # @!attribute [w] skip_paths
      # @!attribute [w] only_paths
      # @!attribute [w] show_run_process
      # @!attribute [w] number_of_workers
      attr_writer :root_path, :skip_paths, :only_paths, :show_run_process, :number_of_workers

      # Get the path.
      #
      # @return [String] default is '.'
      def root_path
        @root_path || '.'
      end

      # Get a list of skip paths.
      #
      # @return [Array<String>] default is [].
      def skip_paths
        @skip_paths || []
      end

      # Get a list of only paths.
      #
      # @return [Array<String>] default is [].
      def only_paths
        @only_paths || []
      end

      # Check if show run process.
      #
      # @return [Boolean] default is false
      def show_run_process
        @show_run_process || false
      end

      # Number of workers
      #
      # @return [Integer] default is 1
      def number_of_workers
        @number_of_workers || 1
      end
    end
  end
end
