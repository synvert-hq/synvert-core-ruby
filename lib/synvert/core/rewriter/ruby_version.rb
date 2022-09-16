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
      if File.exist?(File.join(Configuration.root_path, '.ruby-version'))
        version_file = '.ruby-version'
      elsif File.exist?(File.join(Configuration.root_path, '.rvmrc'))
        version_file = '.rvmrc'
      end
      return true unless version_file

      version = File.read(File.join(Configuration.root_path, version_file))
      Gem::Version.new(version) >= Gem::Version.new(@version)
    end
  end
end
