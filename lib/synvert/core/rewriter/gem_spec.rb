# frozen_string_literal: true

module Synvert::Core
  # GemSpec checks and compares gem version.
  class Rewriter::GemSpec
    # @!attribute [r] name
    #   @return [String] the name of gem_spec
    # @!attribute [r] version
    #   @return [String] the version of gem_spec
    attr_reader :name, :version

    # Initialize a GemSpec.
    #
    # @param name [String] gem name
    # @param version [String] gem version, e.g. '~> 2.0.0'
    def initialize(name, version)
      @name = name
      @version = version
    end

    # Check if the specified gem version in Gemfile.lock matches gem_spec comparator.
    #
    # @return [Boolean] true if matches, otherwise false.
    def match?
      gemfile_lock_path = File.expand_path(File.join(Configuration.root_path, 'Gemfile.lock'))

      # if Gemfile.lock does not exist, just ignore this check
      return true unless File.exist?(gemfile_lock_path)

      ENV['BUNDLE_GEMFILE'] = Configuration.root_path # make sure bundler reads Gemfile.lock in the correct path
      parser = Bundler::LockfileParser.new(File.read(gemfile_lock_path))
      parser.specs.any? { |spec| Gem::Dependency.new(@name, @version).match?(spec) }
    end
  end
end
