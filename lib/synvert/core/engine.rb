# frozen_string_literal: true

module Synvert::Core
  # Engine defines how to encode / decode other files (like erb).
  module Engine
    autoload :Erb, 'synvert/core/engine/erb'
    autoload :Haml, 'synvert/core/engine/haml'

    def self.register(extension, engine)
      @engines ||= {}
      @engines[extension] = engine
    end

    def self.encode(extension, source)
      engine = @engines[extension]
      engine ? engine.encode(source) : source
    end
  end

  Engine.register('.erb', Engine::Erb)
  Engine.register('.haml', Engine::Haml)
end
