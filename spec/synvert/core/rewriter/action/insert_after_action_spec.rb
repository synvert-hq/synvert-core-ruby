# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::InsertAfterAction do
    subject {
      source = "  include Foo"
      node = Parser::CurrentRuby.parse(source)
      instance = double(current_node: node)
      Rewriter::InsertAfterAction.new(instance, 'include Bar')
    }

    it 'gets begin_pos' do
      expect(subject.begin_pos).to eq "  include Foo".length
    end

    it 'gets end_pos' do
      expect(subject.end_pos).to eq "  include Foo".length
    end

    it 'gets rewritten_code' do
      expect(subject.rewritten_code).to eq "\n  include Bar"
    end
  end
end
