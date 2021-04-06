# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::ReplaceAction do
    context 'replace with single line' do
      subject {
        source = "FactoryBot.create(:user)"
        node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: node)
        Rewriter::ReplaceAction.new(instance, :receiver, :dot, :message, with: 'create')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 0
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "FactoryBot.create".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq 'create'
      end
    end
  end
end
