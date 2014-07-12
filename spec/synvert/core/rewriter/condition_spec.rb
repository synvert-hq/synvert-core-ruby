require 'spec_helper'

module Synvert::Core
  describe Rewriter::Condition do
    let(:source) {
      """
      RSpec.configure do |config|
        config.include EmailSpec::Helpers
        config.include EmailSpec::Methods
      end
      """
    }
    let(:node) { Parser::CurrentRuby.parse(source) }
    let(:instance) { double(:current_node => node, :current_source => source) }
    before { Rewriter::Instance.current = instance }

    describe Rewriter::IfExistCondition do
      describe '#process' do
        it 'call block if match anything' do
          run = false
          condition = Rewriter::IfExistCondition.new instance, type: 'send', message: 'include', arguments: ['EmailSpec::Helpers'] do
            run = true
          end
          condition.process
          expect(run).to be_truthy
        end

        it 'not call block if not match anything' do
          run = false
          condition = Rewriter::IfExistCondition.new instance, type: 'send', message: 'include', arguments: ['FactoryGirl::SyntaxMethods'] do
            run = true
          end
          condition.process
          expect(run).to be_falsey
        end
      end
    end

    describe Rewriter::UnlessExistCondition do
      describe '#process' do
        it 'call block if match anything' do
          run = false
          condition = Rewriter::UnlessExistCondition.new instance, type: 'send', message: 'include', arguments: ['FactoryGirl::Syntax::Methods'] do
            run = true
          end
          condition.process
          expect(run).to be_truthy
        end

        it 'not call block if not match anything' do
          run = false
          condition = Rewriter::UnlessExistCondition.new instance, type: 'send', message: 'include', arguments: ['EmailSpec::Helpers'] do
            run = true
          end
          condition.process
          expect(run).to be_falsey
        end
      end
    end

    describe Rewriter::IfOnlyExistCondition do
      describe '#process' do
        it 'gets matching nodes' do
          source = """
            RSpec.configure do |config|
              config.include EmailSpec::Helpers
            end
          """
          node = Parser::CurrentRuby.parse(source)
          instance = double(:current_node => node, :current_source => source)
          Rewriter::Instance.current = instance
          run = false
          condition = Rewriter::IfOnlyExistCondition.new instance, type: 'send', message: 'include', arguments: ['EmailSpec::Helpers'] do
            run = true
          end
          condition.process
          expect(run).to be_truthy
        end

        it 'not call block if does not match' do
          run = false
          condition = Rewriter::IfOnlyExistCondition.new instance, type: 'send', message: 'include', arguments: ['EmailSpec::Helpers'] do
            run = true
          end
          condition.process
          expect(run).to be_falsey
        end
      end
    end
  end
end
