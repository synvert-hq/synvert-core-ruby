# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::PrependAction do
    describe 'block node without args' do
      subject {
        source = "Synvert::Application.configure do\nend"
        block_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: block_node)
        Rewriter::PrependAction.new(instance, 'config.eager_load = true').process
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'Synvert::Application.configure do'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'Synvert::Application.configure do'.length
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
        Rewriter::PrependAction.new(instance, '{{arguments.first}}.include FactoryGirl::Syntax::Methods').process
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'RSpec.configure do |config|'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'RSpec.configure do |config|'.length
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
        Rewriter::PrependAction.new(instance, 'include Deletable').process
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'class User'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'class User'.length
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
        Rewriter::PrependAction.new(instance, 'include Deletable').process
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'class User < ActionRecord::Base'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'class User < ActionRecord::Base'.length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  include Deletable"
      end
    end

    describe 'def node without args' do
      subject do
        source = "def setup\n  do_something\nend"
        def_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: def_node)
        Rewriter::PrependAction.new(instance, 'super').process
      end

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'def setup'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'def setup'.length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  super"
      end
    end

    describe 'def node with args' do
      subject do
        source = "def setup(foobar)\n  do_something\nend"
        def_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: def_node)
        Rewriter::PrependAction.new(instance, 'super').process
      end

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'def setup(foobar)'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'def setup(foobar)'.length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  super"
      end
    end

    describe 'defs node without args' do
      subject do
        source = "def self.foo\n  do_something\nend"
        def_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: def_node)
        Rewriter::PrependAction.new(instance, 'do_something_first').process
      end

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'def self.foo'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'def self.foo'.length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  do_something_first"
      end
    end

    describe 'defs node with args' do
      subject do
        source = "def self.foo(bar)\n  do_something\nend"
        def_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: def_node)
        Rewriter::PrependAction.new(instance, 'do_something_first').process
      end

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'def self.foo(bar)'.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'def self.foo(bar)'.length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n  do_something_first"
      end
    end
  end
end
