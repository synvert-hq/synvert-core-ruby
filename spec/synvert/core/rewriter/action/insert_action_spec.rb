# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::InsertAction do
    context 'at end' do
      subject {
        source = "  User.where(username: 'Richard')"
        node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: node)
        Rewriter::InsertAction.new(instance, '.first', at: 'end')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "  User.where(username: 'Richard')".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "  User.where(username: 'Richard')".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq '.first'
      end
    end

    context 'at beginning' do
      subject {
        source = "  open('http://test.com')"
        node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: node)
        Rewriter::InsertAction.new(instance, 'URI.', at: 'beginning')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 2
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 2
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq 'URI.'
      end
    end
  end
end
