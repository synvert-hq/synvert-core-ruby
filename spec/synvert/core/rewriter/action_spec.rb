# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::Action do
    subject {
      source = "before_save do\n  return false\nend"
      block_node = Parser::CurrentRuby.parse(source).body.first
      instance = double(current_node: block_node)
      Rewriter::Action.new(instance, source)
    }
  end
end
