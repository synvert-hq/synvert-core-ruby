# frozen_string_literal: true

module Synvert::Core
  module Engine
    class Erb
      class << self
        # Encode erb string, leave only ruby code, replace other erb code with whitespace.
        #
        # @param source [String] erb code.
        # @return [String] encoded ruby code.
        def encode(source)
          source.gsub(/%>.*?<%=?/m) { |str| ' ' * str.size }
                .sub(/^.*?<%=?/m) { |str| ' ' * str.size }
                .sub(/%>.*?$/m) { |str| ' ' * str.size }
        end
      end
    end
  end
end
