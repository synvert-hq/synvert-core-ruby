require 'spec_helper'

module Synvert::Core
  describe Rewriter::Warning do
    subject do
      source = "def test\n  debugger\nend"
      send_node = Parser::CurrentRuby.parse(source).body.first
      instance = double(current_node: send_node, current_file: 'app/test.rb')
      Rewriter::Warning.new(instance, 'remove debugger')
    end

    it 'gets message with filename and line number' do
      expect(subject.message).to eq 'app/test.rb#2: remove debugger'
    end
  end
end
