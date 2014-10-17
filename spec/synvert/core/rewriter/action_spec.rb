require 'spec_helper'

module Synvert::Core
  describe Rewriter::Action do
    subject {
      source = "before_save do\n  return false\nend"
      block_node = Parser::CurrentRuby.parse(source).body.first
      instance = double(current_node: block_node)
      Rewriter::Action.new(instance, source)
    }

    it 'gets line' do
      expect(subject.line).to eq 2
    end
  end
end
