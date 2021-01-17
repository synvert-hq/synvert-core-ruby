# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::UnlessExistCondition do
    let(:source) do
      '' \
        '
      RSpec.configure do |config|
        config.include EmailSpec::Helpers
        config.include EmailSpec::Methods
      end
      ' \
        ''
    end
    let(:node) { Parser::CurrentRuby.parse(source) }
    let(:instance) { double(current_node: node) }

    describe '#process' do
      it 'call block if match anything' do
        run = false
        condition =
          Rewriter::UnlessExistCondition.new instance,
                                             type: 'send',
                                             message: 'include',
                                             arguments: ['FactoryGirl::Syntax::Methods'] do
            run = true
          end
        condition.process
        expect(run).to be_truthy
      end

      it 'not call block if not match anything' do
        run = false
        condition =
          Rewriter::UnlessExistCondition.new instance,
                                             type: 'send', message: 'include', arguments: ['EmailSpec::Helpers'] do
            run = true
          end
        condition.process
        expect(run).to be_falsey
      end
    end
  end
end
