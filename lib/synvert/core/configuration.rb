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
      # @!attribute [w] single_quote
      # @!attribute [w] tab_width
      # @!attribute [w] strict, if strict is false, it will ignore ruby version and gem version check.
      attr_writer :root_path,
                  :skip_paths,
                  :only_paths,
                  :show_run_process,
                  :number_of_workers,
                  :single_quote,
                  :tab_width,
                  :strict

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

      # Use single quote or double quote.
      #
      # @return [Boolean] true if use single quote, default is true
      def single_quote
        @single_quote.nil? ? true : @single_quote
      end

      # Returns the tab width used for indentation.
      #
      # If the tab width is not explicitly set, it defaults to 2.
      #
      # @return [Integer] The tab width.
      def tab_width
        @tab_width || 2
      end

      # Returns the value of the strict flag.
      #
      # If the strict flag is not set, it returns true by default.
      #
      # @return [Boolean] the value of the strict flag
      def strict
        @strict.nil? ? true : @strict
      end
    end
  end
end
