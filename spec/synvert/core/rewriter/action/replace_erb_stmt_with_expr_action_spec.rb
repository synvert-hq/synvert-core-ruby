# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  RSpec.describe Rewriter::ReplaceErbStmtWithExprAction do
    context 'replace with whitespace' do
      subject {
        erb_source = "<% form_for post do |f| %>\n<% end %>"
        source = Engine::Erb.encode(erb_source)
        node = parser_parse(source).children.first
        described_class.new(node, erb_source, adapter: NodeMutation::ParserAdapter.new).process
      }

      it 'gets start' do
        expect(subject.start).to eq '<%'.length
      end

      it 'gets end' do
        expect(subject.end).to eq '<%'.length
      end

      it 'gets new_code' do
        expect(subject.new_code).to eq '='
      end
    end

    context 'replace without whitespace' do
      subject {
        erb_source = "<%form_for post do |f|%>\n<%end%>"
        source = Engine::Erb.encode(erb_source)
        node = parser_parse(source).children.first
        described_class.new(node, erb_source, adapter: NodeMutation::ParserAdapter.new).process
      }

      it 'gets start' do
        expect(subject.start).to eq '<%'.length
      end

      it 'gets end' do
        expect(subject.end).to eq '<%'.length
      end

      it 'gets new_code' do
        expect(subject.new_code).to eq '='
      end
    end
  end
end
