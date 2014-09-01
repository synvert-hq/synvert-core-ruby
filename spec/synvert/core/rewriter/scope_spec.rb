require 'spec_helper'

module Synvert::Core
  describe Rewriter::WithinScope do
    let(:source) {"""
describe Post do
  it 'gets post' do
    FactoryGirl.create :post
  end
end
    """}
    let(:node) { Parser::CurrentRuby.parse(source) }
    let(:instance) { double(:current_node => node, :current_node= => node) }
    before { allow(instance).to receive(:process_with_node).and_yield }

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
        scope = Rewriter::WithinScope.new instance, type: 'send', receiver: 'FactoryGirl', message: 'create', arguments: [':post'] do
          run = true
        end
        scope.process
        expect(run).to be_truthy
      end
    end
  end

  describe Rewriter::GotoScope do
    let(:source) {'''
Factory.define :user do |user|
end
    '''}
    let(:node) { Parser::CurrentRuby.parse(source) }
    let(:instance) { double(:current_node => node, :current_node= => node) }
    before { allow(instance).to receive(:process_with_node).and_yield }

    describe '#process' do
      it 'call block with child node' do
        run = false
        scope = Rewriter::GotoScope.new instance, :caller do
          run = true
        end
        scope.process
        expect(run).to be_truthy
      end
    end
  end
end
