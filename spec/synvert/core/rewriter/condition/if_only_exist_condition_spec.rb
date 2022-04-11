# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::IfOnlyExistCondition do
    let(:source) {
      '
      RSpec.configure do |config|
        config.include EmailSpec::Helpers
        config.include EmailSpec::Methods
      end
      '
    }
    let(:node) { Parser::CurrentRuby.parse(source) }
    let(:instance) { double(current_node: node) }

    describe '#process' do
      it 'gets matching nodes' do
        source = ' RSpec.configure do |config| config.include EmailSpec::Helpers end '
        node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: node)
        run = false
        condition =
          Rewriter::IfOnlyExistCondition.new instance,
                                             type: 'send',
                                             message: 'include',
                                             arguments: ['EmailSpec::Helpers'] do
            run = true
          end
        condition.process
        expect(run).to be_truthy
      end

      it 'not call block if does not match' do
        run = false
        condition =
          Rewriter::IfOnlyExistCondition.new instance,
                                             type: 'send',
                                             message: 'include',
                                             arguments: ['EmailSpec::Helpers'] do
            run = true
          end
        condition.process
        expect(run).to be_falsey
      end
    end
  end
end
