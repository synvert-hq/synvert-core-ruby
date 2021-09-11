# frozen_string_literal: true

module Synvert::Core
  # Synvert global configuration.
  class Configuration
    class << self
      attr_writer :path, :skip_files, :show_run_process

      def path
        @path || '.'
      end

      def skip_files
        @skip_files || []
      end

      def show_run_process
        @show_run_process || false
      end
    end
  end
end
