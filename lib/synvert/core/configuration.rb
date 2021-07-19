# frozen_string_literal: true

module Synvert::Core
  # Synvert global configuration.
  class Configuration
    class << self
      attr_writer :path, :skip_files

      def path
        @path || File.absolute_path('.')
      end

      def skip_files
        @skip_files || []
      end
    end
  end
end
