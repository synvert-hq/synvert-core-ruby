# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::QueryScope do
    let(:instance) {
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new(rewriter, 'file pattern')
    }
    let(:source) { <<~EOS }
      describe Post do
        it 'gets post' do
          FactoryGirl.create :post
        end
      end
    EOS

    let(:node) { Parser::CurrentRuby.parse(source) }

    before do
      Rewriter::Instance.reset
      instance.current_node = node
    end

    describe '#process' do
      it 'not call block if no matching node' do
        run = false
        scope =
          described_class.new instance, '.send[message=missing]' do
            run = true
          end
        scope.process
        expect(run).to be_falsey
      end

      it 'call block if there is matching node' do
        run = false
        type_in_scope = nil
        scope =
          described_class.new instance, '.send[receiver=FactoryGirl][message=create][arguments=(:post)]' do
            run = true
            type_in_scope = node.type
          end
        scope.process
        expect(run).to be_truthy
        expect(type_in_scope).to eq :send
        expect(instance.current_node.type).to eq :block
      end

      it 'matches multiple block nodes' do
        block_nodes = []
        scope =
          described_class.new(instance, '.block') do
            block_nodes << node
          end
        scope.process
        expect(block_nodes.size).to eq 2
      end
    end
  end
end
