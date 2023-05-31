# frozen_string_literal: true

module Synvert::Core
  class Helper
    attr_reader :name, :block

    class << self
      # Register a helper with its name.
      #
      # @param name [String] the unique rewriter name.
      # @param helper [Synvert::Core::Helper] the helper to register.
      def register(name, helper)
        name = name.to_s
        helpers[name] = helper
      end

      # Fetch a helper by name.
      #
      # @param name [String] rewrtier name.
      # @return [Synvert::Core::Helper] the matching helper.
      def fetch(name)
        name = name.to_s
        helpers[name]
      end

      # Get all available helpers
      #
      # @return [Hash<String, Synvert::Core::Helper>]
      def availables
        helpers
      end

      # Clear all registered helpers.
      def clear
        helpers.clear
      end

      private

      def helpers
        @helpers ||= {}
      end
    end

    def initialize(name, &block)
      @name = name
      @block = block
      self.class.register(name, self)
    end
  end
end