# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::GotoScope do
    let(:instance) {
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new(rewriter, 'file pattern')
    }
    let(:source) { <<~EOS }
      Factory.define :user do |user|
      end
    EOS

    let(:node) { Parser::CurrentRuby.parse(source) }
    before do
      Rewriter::Instance.reset
      instance.current_node = node
    end

    describe '#process' do
      it 'call block with child node' do
        run = false
        type_in_scope = nil
        scope =
          Rewriter::GotoScope.new instance, 'caller.receiver' do
            run = true
            type_in_scope = node.type
          end
        scope.process
        expect(run).to be_truthy
        expect(type_in_scope).to eq :const
        expect(instance.current_node.type).to eq :block
      end
    end
  end
end
