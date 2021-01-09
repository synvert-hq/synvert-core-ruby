module Synvert::Core
  # Engine defines how to encode / decode other files (like erb).
  module Engine
    autoload :ERB, 'synvert/core/engine/erb'
  end
end
