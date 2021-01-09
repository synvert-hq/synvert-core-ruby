# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::Instance do
    before { Rewriter::Instance.reset }

    let(:instance) do
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new(rewriter, 'file pattern')
    end

    it 'parses within_node' do
      scope = double
      block = Proc.new {}
      expect(Rewriter::WithinScope).to receive(:new).with(instance, type: 'send', message: 'create', &block)
        .and_return(scope)
      expect(scope).to receive(:process)
      instance.within_node(type: 'send', message: 'create', &block)
    end

    it 'parses with_node' do
      scope = double
      block = Proc.new {}
      expect(Rewriter::WithinScope).to receive(:new).with(instance, type: 'send', message: 'create', &block)
        .and_return(scope)
      expect(scope).to receive(:process)
      instance.with_node(type: 'send', message: 'create', &block)
    end

    it 'parses goto_node' do
      scope = double
      block = Proc.new {}
      expect(Rewriter::GotoScope).to receive(:new).with(instance, :caller, &block).and_return(scope)
      expect(scope).to receive(:process)
      instance.goto_node(:caller, &block)
    end

    it 'parses if_exist_node' do
      condition = double
      block = Proc.new {}
      expect(Rewriter::IfExistCondition).to receive(:new).with(instance, type: 'send', message: 'create', &block)
        .and_return(condition)
      expect(condition).to receive(:process)
      instance.if_exist_node(type: 'send', message: 'create', &block)
    end

    it 'parses unless_exist_node' do
      condition = double
      block = Proc.new {}
      expect(Rewriter::UnlessExistCondition).to receive(:new).with(instance, type: 'send', message: 'create', &block)
        .and_return(condition)
      expect(condition).to receive(:process)
      instance.unless_exist_node(type: 'send', message: 'create', &block)
    end

    it 'parses if_only_exist_node' do
      condition = double
      block = Proc.new {}
      expect(Rewriter::IfOnlyExistCondition).to receive(:new).with(instance, type: 'send', message: 'create', &block)
        .and_return(condition)
      expect(condition).to receive(:process)
      instance.if_only_exist_node(type: 'send', message: 'create', &block)
    end

    it 'parses append' do
      expect(Rewriter::AppendAction).to receive(:new).with(instance, 'include FactoryGirl::Syntax::Methods', {})
      instance.append 'include FactoryGirl::Syntax::Methods'
    end

    it 'parses insert' do
      expect(Rewriter::InsertAction).to receive(:new).with(
        instance,
        '{{arguments.first}}.include FactoryGirl::Syntax::Methods',
        {}
      )
      instance.insert '{{arguments.first}}.include FactoryGirl::Syntax::Methods'
    end

    it 'parses insert_after' do
      expect(Rewriter::InsertAfterAction).to receive(:new).with(
        instance,
        '{{arguments.first}}.include FactoryGirl::Syntax::Methods',
        {}
      )
      instance.insert_after '{{arguments.first}}.include FactoryGirl::Syntax::Methods'
    end

    it 'parses replace_with' do
      expect(Rewriter::ReplaceWithAction).to receive(:new).with(instance, 'create {{arguments}}', {})
      instance.replace_with 'create {{arguments}}'
    end

    it 'parses remove' do
      expect(Rewriter::RemoveAction).to receive(:new).with(instance)
      instance.remove
    end

    it 'parses warn' do
      expect(Rewriter::Warning).to receive(:new).with(instance, 'foobar')
      instance.warn 'foobar'
    end

    describe '#process' do
      let(:rewriter) { Rewriter.new('foo', 'bar') }

      it 'writes new code to file' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/**/*_spec.rb' do
            with_node type: 'send', receiver: 'FactoryGirl', message: 'create' do
              replace_with 'create {{arguments}}'
            end
          end
        input =
          '' \
            "
it 'uses factory_girl' do
  user = FactoryGirl.create :user
  post = FactoryGirl.create :post, user: user
  assert post.valid?
end
" \
            ''
        output =
          '' \
            "
it 'uses factory_girl' do
  user = create :user
  post = create :post, user: user
  assert post.valid?
end
" \
            ''
        expect(Dir).to receive(:glob).with('./spec/**/*_spec.rb').and_return(['spec/models/post_spec.rb'])
        expect(File).to receive(:read).with('spec/models/post_spec.rb').and_return(input)
        expect(File).to receive(:write).with('spec/models/post_spec.rb', output)
        instance.process
      end

      it 'does not write if file content is not changed' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/spec_helper.rb' do
            with_node type: 'block', caller: { receiver: 'RSpec', message: 'configure' } do
              unless_exist_node type: 'send', message: 'include', arguments: ['FactoryGirl::Syntax::Methods'] do
                insert '{{arguments.first}}.include FactoryGirl::Syntax::Methods'
              end
            end
          end
        input =
          '' \
            '
        RSpec.configure do |config|
          config.include FactoryGirl::Syntax::Methods
        end
        ' \
            ''
        output =
          '' \
            '
        RSpec.configure do |config|
          config.include FactoryGirl::Syntax::Methods
        end
        ' \
            ''
        expect(Dir).to receive(:glob).with('./spec/spec_helper.rb').and_return(['spec/spec_helper.rb'])
        expect(File).to receive(:read).with('spec/spec_helper.rb').and_return(input)
        expect(File).not_to receive(:write).with('spec/spec_helper.rb', output)
        instance.process
      end

      it 'does not read file if already read' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/spec_helper.rb' do
            with_node type: 'block', caller: { receiver: 'RSpec', message: 'configure' } do
              unless_exist_node type: 'send', message: 'include', arguments: ['FactoryGirl::Syntax::Methods'] do
                insert '{{arguments.first}}.include FactoryGirl::Syntax::Methods'
              end
            end
          end
        input =
          '' \
            '
        RSpec.configure do |config|
          config.include FactoryGirl::Syntax::Methods
        end
        ' \
            ''
        output =
          '' \
            '
        RSpec.configure do |config|
          config.include FactoryGirl::Syntax::Methods
        end
        ' \
            ''
        expect(Dir).to receive(:glob).with('./spec/spec_helper.rb').and_return(['spec/spec_helper.rb']).twice
        expect(File).to receive(:read).with('spec/spec_helper.rb').and_return(input).once
        expect(File).not_to receive(:write).with('spec/spec_helper.rb', output)
        instance.process
        instance.process
      end

      it 'updates file_source and file_ast when writing a file' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/**/*_spec.rb' do
            with_node type: 'send', receiver: 'FactoryGirl', message: 'create' do
              replace_with 'create {{arguments}}'
            end
          end
        input =
          '' \
            "
it 'uses factory_girl' do
  user = FactoryGirl.create :user
  post = FactoryGirl.create :post, user: user
  assert post.valid?
end
" \
            ''
        output =
          '' \
            "
it 'uses factory_girl' do
  user = create :user
  post = create :post, user: user
  assert post.valid?
end
" \
            ''
        expect(Dir).to receive(:glob).with('./spec/**/*_spec.rb').and_return(['spec/models/post_spec.rb']).twice
        expect(File).to receive(:read).with('spec/models/post_spec.rb').and_return(input)
        expect(File).to receive(:write).with('spec/models/post_spec.rb', output)
        expect(File).to receive(:read).with('spec/models/post_spec.rb').and_return(output)
        instance.process
        instance.process
      end
    end

    describe '#get_conflict_actions' do
      let(:rewriter) { Rewriter.new('foo', 'bar') }

      it 'has no conflict' do
        action1 = double(begin_pos: 10, end_pos: 20)
        action2 = double(begin_pos: 30, end_pos: 40)
        action3 = double(begin_pos: 50, end_pos: 60)
        instance = Rewriter::Instance.new rewriter, 'spec/spec_helper.rb'
        instance.instance_variable_set :@actions, [action1, action2, action3]
        conflict_actions = instance.send(:get_conflict_actions)
        expect(conflict_actions).to eq []
        expect(instance.instance_variable_get(:@actions)).to eq [action1, action2, action3]
      end

      it 'has no conflict' do
        action1 = double(begin_pos: 30, end_pos: 40)
        action2 = double(begin_pos: 50, end_pos: 60)
        action3 = double(begin_pos: 10, end_pos: 20)
        instance = Rewriter::Instance.new rewriter, 'spec/spec_helper.rb'
        instance.instance_variable_set :@actions, [action1, action2, action3]
        conflict_actions = instance.send(:get_conflict_actions)
        expect(conflict_actions).to eq [action2, action1]
        expect(instance.instance_variable_get(:@actions)).to eq [action3]
      end
    end

    describe '#process_with_node' do
      it 'resets current_node' do
        node1 = double
        node2 = double
        instance.process_with_node(node1) do
          instance.current_node = node2
          expect(instance.current_node).to eq node2
        end
        expect(instance.current_node).to eq node1
      end
    end

    describe '#process_with_other_node' do
      it 'resets current_node' do
        node1 = double
        node2 = double
        node3 = double
        instance.current_node = node1
        instance.process_with_other_node(node2) do
          instance.current_node = node3
          expect(instance.current_node).to eq node3
        end
        expect(instance.current_node).to eq node1
      end
    end
  end
end
