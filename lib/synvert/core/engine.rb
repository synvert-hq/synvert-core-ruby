# frozen_string_literal: true

module Synvert::Core
  # Engine defines how to encode / decode other files (like erb).
  module Engine
    autoload :Erb, 'synvert/core/engine/erb'
  end
end
