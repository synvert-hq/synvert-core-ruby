# frozen_string_literal: true

module Synvert::Core
  # Engine defines how to encode / decode other files (like erb).
  module Engine
    autoload :Erb, 'synvert/core/engine/erb'
    autoload :Haml, 'synvert/core/engine/haml'

    # Register an engine
    # @param [String] extension
    # @param [Class] engine
    def self.register(extension, engine)
      @engines ||= {}
      @engines[extension] = engine
    end

    # Encode source code by registered engine.
    # @param [String] extension
    # @param [String] source
    # @return [String] encoded source
    def self.encode(extension, source)
      engine = @engines[extension]
      engine ? engine.encode(source) : source
    end

    # Generate a transform_proc by registered engine,
    # which is used to adjust start and end position of actions.
    # @param [String] extension
    # @param [String] encoded_source
    # @return [Proc] transform_proc
    def self.generate_transform_proc(extension, encoded_source)
      engine = @engines[extension]
      engine ? engine.generate_transform_proc(encoded_source) : proc {}
    end
  end

  Engine.register('.erb', Engine::Erb)
  Engine.register('.haml', Engine::Haml)
end
