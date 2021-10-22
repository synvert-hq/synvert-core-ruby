# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::WrapAction do
    subject do
      source = "class Bar\nend"
      node = Parser::CurrentRuby.parse(source)
      instance = double(current_node: node)
      Rewriter::WrapAction.new(instance, with: 'module Foo').process
    end

    it 'gets begin_pos' do
      expect(subject.begin_pos).to eq 0
    end

    it 'gets end_pos' do
      expect(subject.end_pos).to eq "class Bar\nend".length
    end

    it 'gets rewritten_code' do
      expect(subject.rewritten_code).to eq <<~EOS.strip
        module Foo
          class Bar
          end
        end
      EOS
    end
  end
end
