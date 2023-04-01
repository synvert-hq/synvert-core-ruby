# frozen_string_literal: true

module Synvert::Core
  module Engine
    class Haml
      class << self
        # Encode haml string, leave only ruby code, replace other haml code with whitespace.
        #
        # @param source [String] haml code.
        # @return [String] encoded ruby code.
        def encode(source)
          source.lines.map do |line|
            if line =~ /\A(\s*-)/ || # match "  - if current_user"
               line =~ /\A(\s*([%#\.].*)?=)/ # match "  %span= current_user.login"
              ' ' * $1.size + line[$1.size..]
            else
              ' ' * line.size
            end
          end.join("\n")
        end
      end
    end
  end
end
