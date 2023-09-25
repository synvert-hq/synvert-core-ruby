# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::WithinScope do
    let(:instance) {
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new(rewriter, 'file pattern')
    }
    let(:source) { <<~EOS }
      describe User do
        describe 'create' do
          it 'creates user' do
            FactoryGirl.create :user
          end
        end
      end
    EOS

    let(:node) { Parser::CurrentRuby.parse(source) }

    before { instance.current_node = node }

    describe '#process' do
      context 'rules' do
        it 'not call block if no matching node' do
          run = false
          scope =
            Rewriter::WithinScope.new instance, type: 'send', message: 'missing' do
              run = true
            end
          scope.process
          expect(run).to be_falsey
        end

        it 'call block if there is matching node' do
          run = false
          type_in_scope = nil
          scope =
            Rewriter::WithinScope.new instance,
                                      type: 'send',
                                      receiver: 'FactoryGirl',
                                      message: 'create',
                                      arguments: [':user'] do
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
            Rewriter::WithinScope.new(instance, { type: 'block' }) do
              block_nodes << node
            end
          scope.process
          expect(block_nodes.size).to eq 3
        end

        it 'matches only 2 block nodes if including_self is false' do
          block_nodes = []
          scope =
            Rewriter::WithinScope.new(instance, { type: 'block' }, { including_self: false }) do
              block_nodes << node
            end
          scope.process
          expect(block_nodes.size).to eq 2
        end

        it 'matches only one block node if recursive is false' do
          block_nodes = []
          scope =
            Rewriter::WithinScope.new(instance, { type: 'block' }, { recursive: false }) do
              block_nodes << node
            end
          scope.process
          expect(block_nodes.size).to eq 1
        end

        it 'matches only one block node if stop_at_first_match is true' do
          block_nodes = []
          scope =
            Rewriter::WithinScope.new(instance, { type: 'block' }, { stop_at_first_match: true }) do
              block_nodes << node
            end
          scope.process
          expect(block_nodes.size).to eq 1
        end
      end

      context 'nql' do
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
            described_class.new instance, '.send[receiver=FactoryGirl][message=create][arguments=(:user)]' do
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
          expect(block_nodes.size).to eq 3
        end

        it 'raises InvalidOperatorError' do
          scope = described_class.new(instance, '.send[receiver IN FactoryGirl]') {}
          expect {
            scope.process
          }.to raise_error(NodeQuery::Compiler::InvalidOperatorError)
        end
      end
    end
  end
end
