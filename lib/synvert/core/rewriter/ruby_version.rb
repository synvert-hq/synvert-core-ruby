# frozen_string_literal: true

module Synvert::Core
  # GemSpec checks and compares gem version.
  class Rewriter::RubyVersion
    # Initialize a ruby_version.
    #
    # @param version [String] ruby version
    def initialize(version)
      @version = version
    end

    # Check if the specified ruby version matches current ruby version.
    #
    # @return [Boolean] true if matches, otherwise false.
    def match?
      # Gem::Version initialize will strip RUBY_VERSION directly in ruby 1.9,
      # which is solved from ruby 2.0.0, which calls dup internally.
      Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new(@version)
    end
  end
end
