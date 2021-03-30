# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::ReplaceAction do
    context 'replace with single line' do
      subject {
        source = "'slug from title'.gsub(' ', '_')"
        node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: node)
        Rewriter::ReplaceAction.new(instance, :message, with: 'tr')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "'slug from title'.".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "'slug from title'.gsub".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq 'tr'
      end
    end
  end
end
