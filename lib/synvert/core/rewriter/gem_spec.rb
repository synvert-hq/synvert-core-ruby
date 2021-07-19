# frozen_string_literal: true

module Synvert::Core
  # GemSpec checks and compares gem version.
  class Rewriter::GemSpec
    attr_reader :name, :version

    # Initialize a gem_spec.
    #
    # @param name [String] gem name
    # @param version [String] gem version, e.g. '~> 2.0.0',
    def initialize(name, version)
      @name = name
      @version = version
    end

    # Check if the specified gem version in Gemfile.lock matches gem_spec comparator.
    #
    # @return [Boolean] true if matches, otherwise false.
    # @raise [Synvert::Core::GemfileLockNotFound] raise if Gemfile.lock does not exist.
    def match?
      gemfile_lock_path = File.join(Configuration.path, 'Gemfile.lock')

      # if Gemfile.lock does not exist, just ignore this check
      return true unless File.exist?(gemfile_lock_path)

      ENV['BUNDLE_GEMFILE'] = Configuration.path # make sure bundler reads Gemfile.lock in the correct path
      puts '================='
      puts ENV['BUNDLE_GEMFILE']
      puts gemfile_lock_path
      parser = Bundler::LockfileParser.new(File.read(gemfile_lock_path))
      parser.specs.any? { |spec| Gem::Dependency.new(@name, @version).match?(spec) }
    end
  end
end
