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
        user.first_name 'First'
        user.last_name 'Last'
      end
    EOS

    let(:node) { Parser::CurrentRuby.parse(source) }
    before { instance.current_node = node }

    describe '#process' do
      it 'calls block with child node' do
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

      it 'calls block multiple times with blok body' do
        count = 0
        scope =
          Rewriter::GotoScope.new instance, 'body' do
            count += 1
          end
        scope.process
        expect(count).to eq 2
        expect(instance.current_node.type).to eq :block
      end
    end
  end
end
