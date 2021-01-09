# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::WithinScope do
    let(:instance) {
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new(rewriter, 'file pattern')
    }
    let(:source) {"""
describe Post do
  it 'gets post' do
    FactoryGirl.create :post
  end
end
    """
    }
    let(:node) { Parser::CurrentRuby.parse(source) }
    before do
      Rewriter::Instance.reset
      instance.current_node = node
    end

    describe '#process' do
      it 'not call block if no matching node' do
        run = false
        scope = Rewriter::WithinScope.new instance, type: 'send', message: 'missing' do
          run = true
        end
        scope.process
        expect(run).to be_falsey
      end

      it 'call block if there is matching node' do
        run = false
        type_in_scope = nil
        scope = Rewriter::WithinScope.new instance, type: 'send', receiver: 'FactoryGirl', message: 'create', arguments: [':post'] do
          run = true
          type_in_scope = node.type
        end
        scope.process
        expect(run).to be_truthy
        expect(type_in_scope).to eq :send
        expect(instance.current_node.type).to eq :block
      end
    end
  end
end
