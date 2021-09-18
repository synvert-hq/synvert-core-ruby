# frozen_string_literal: true

module Synvert::Core
  # GemSpec checks and compares ruby version.
  class Rewriter::RubyVersion
    attr_reader :version

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
      if File.exist?(File.join(Configuration.path, '.ruby-version'))
        versionFile = '.ruby-version'
      elsif File.exist?(File.join(Configuration.path, '.rvmrc'))
        versionFile = '.rvmrc'
      end
      return true unless versionFile

      version = File.read(File.join(Configuration.path, versionFile))
      Gem::Version.new(version) >= Gem::Version.new(@version)
    end
  end
end
