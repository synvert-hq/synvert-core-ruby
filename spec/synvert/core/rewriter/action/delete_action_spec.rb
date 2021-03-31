# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::DeleteAction do
    subject {
      source = "arr.map {}.flatten"
      node = Parser::CurrentRuby.parse(source)
      instance = double(current_node: node)
      Rewriter::DeleteAction.new(instance, :dot, :message)
    }

    it 'gets begin_pos' do
      expect(subject.begin_pos).to eq "arr.map {}".length
    end

    it 'gets end_pos' do
      expect(subject.end_pos).to eq "arr.map {}.flatten".length
    end

    it 'gets rewritten_code' do
      expect(subject.rewritten_code).to eq ''
    end
  end
end
