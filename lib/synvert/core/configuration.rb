# encoding: utf-8
# frozen_string_literal: true

require 'singleton'

module Synvert::Core
  # Synvert global configuration.
  class Configuration < Hash
    include Singleton

    # Set the configuration.
    #
    # @param key [String] configuration key.
    # @param value [Object] configuration value.
    def set(key, value)
      self[key] = value
    end

    # Get the configuration.
    #
    # @param key [String] configuration key.
    # @return [Object] configuration value.
    def get(key)
      self[key]
    end
  end
end
