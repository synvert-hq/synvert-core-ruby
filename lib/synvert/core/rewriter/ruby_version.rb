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
      Gem::Version.new(RUBY_VERSION) >= Gem::Version.new(@version)
    end
  end
end
