require 'spec_helper'

module Synvert::Core
  describe Rewriter::InsertAction do
    describe 'block node without args' do
      subject {
        source = "Synvert::Application.configure do\nend"
        block_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: block_node)
        Rewriter::InsertAction.new(instance, 'config.eager_load = true')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "Synvert::Application.configure do".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "Synvert::Application.configure do".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  config.eager_load = true"
      end
    end

    describe 'block node with args' do
      subject {
        source = "RSpec.configure do |config|\nend"
        block_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: block_node)
        Rewriter::InsertAction.new(instance, '{{arguments.first}}.include FactoryGirl::Syntax::Methods')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "RSpec.configure do |config|".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "RSpec.configure do |config|".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  config.include FactoryGirl::Syntax::Methods"
      end
    end

    describe 'class node without superclass' do
      subject {
        source = "class User\n  has_many :posts\nend"
        class_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: class_node)
        Rewriter::InsertAction.new(instance, 'include Deletable')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "class User".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "class User".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  include Deletable"
      end
    end

    describe 'class node with superclass' do
      subject {
        source = "class User < ActiveRecord::Base\n  has_many :posts\nend"
        class_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: class_node)
        Rewriter::InsertAction.new(instance, 'include Deletable')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "class User < ActionRecord::Base".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "class User < ActionRecord::Base".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  include Deletable"
      end
    end
  end
end
