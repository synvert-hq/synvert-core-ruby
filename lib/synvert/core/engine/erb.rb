# frozen_string_literal: true

require 'erubis'

module Synvert::Core
  module Engine
    class Erb
      class << self
        # convert erb to ruby code.
        #
        # @param source [String] erb source code.
        # @return [String] ruby source code.
        def encode(source)
          source.gsub(/^.*?<%=?/m) { |str| ' ' * str.size }
                .gsub(/%>.*?$/m) { |str| ' ' * str.size }
                .gsub(/%>.*?<%=?/m) { |str| ' ' * str.size }
        end
      end
    end
  end
end
