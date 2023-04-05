# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::Instance do
    let(:instance) {
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new(rewriter, 'code.rb')
    }

    it 'parses find_node' do
      scope = double
      block = proc {}
      expect(Rewriter::WithinScope).to receive(:new).with(
        instance,
        '.send[message=create]',
        {},
        &block
      ).and_return(scope)
      expect(scope).to receive(:process)
      instance.find_node('.send[message=create]', &block)
    end

    it 'raises ParseError when parsing invalid nql' do
      block = proc {}
      expect {
        instance.find_node('synvert', &block)
      }.to raise_error(NodeQuery::Compiler::ParseError)

      expect {
        instance.find_node('.block <caller.arguments> .hash', &block)
      }.to raise_error(NodeQuery::Compiler::ParseError)
    end

    it 'parses within_node' do
      scope = double
      block = proc {}
      expect(Rewriter::WithinScope).to receive(:new)
        .with(instance, { type: 'send', message: 'create' }, {}, &block)
        .and_return(scope)
      expect(scope).to receive(:process)
      instance.within_node(type: 'send', message: 'create', &block)
    end

    it 'parses with_node' do
      scope = double
      block = proc {}
      expect(Rewriter::WithinScope).to receive(:new)
        .with(instance, { type: 'send', message: 'create' }, {}, &block)
        .and_return(scope)
      expect(scope).to receive(:process)
      instance.with_node(type: 'send', message: 'create', &block)
    end

    it 'parses within_node with stop_at_first_match true' do
      scope = double
      block = proc {}
      expect(Rewriter::WithinScope).to receive(:new)
        .with(instance, { type: 'send', message: 'create' }, { stop_at_first_match: true }, &block)
        .and_return(scope)
      expect(scope).to receive(:process)
      instance.within_node({ type: 'send', message: 'create' }, { stop_at_first_match: true }, &block)
    end

    it 'parses goto_node' do
      scope = double
      block = proc {}
      expect(Rewriter::GotoScope).to receive(:new).with(instance, 'caller.receiver', &block).and_return(scope)
      expect(scope).to receive(:process)
      instance.goto_node('caller.receiver', &block)
    end

    it 'parses if_exist_node' do
      condition = double
      block = proc {}
      expect(Rewriter::IfExistCondition).to receive(:new)
        .with(instance, { type: 'send', message: 'create' }, &block)
        .and_return(condition)
      expect(condition).to receive(:process)
      instance.if_exist_node(type: 'send', message: 'create', &block)
    end

    it 'parses unless_exist_node' do
      condition = double
      block = proc {}
      expect(Rewriter::UnlessExistCondition).to receive(:new)
        .with(instance, { type: 'send', message: 'create' }, &block)
        .and_return(condition)
      expect(condition).to receive(:process)
      instance.unless_exist_node(type: 'send', message: 'create', &block)
    end

    it 'parses if_only_exist_node' do
      condition = double
      block = proc {}
      expect(Rewriter::IfOnlyExistCondition).to receive(:new)
        .with(instance, { type: 'send', message: 'create' }, &block)
        .and_return(condition)
      expect(condition).to receive(:process)
      instance.if_only_exist_node(type: 'send', message: 'create', &block)
    end

    it 'parses append' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:append).with(
        instance.current_node,
        'Foobar'
      )
      instance.append 'Foobar'
    end

    it 'parses prepend' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:prepend).with(
        instance.current_node,
        'Foobar'
      )
      instance.prepend 'Foobar'
    end

    it 'parses insert at end' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:insert).with(
        instance.current_node,
        'Foobar',
        at: 'end',
        to: 'receiver',
        and_comma: false
      )
      instance.insert 'Foobar', to: 'receiver'
    end

    it 'parses insert at beginning' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:insert).with(
        instance.current_node,
        'Foobar',
        at: 'beginning',
        to: nil,
        and_comma: false
      )
      instance.insert 'Foobar', at: 'beginning'
    end

    it 'parses insert_after' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(NodeMutation).to receive_message_chain(:adapter, :get_start_loc, :column).and_return(2)
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:insert).with(
        instance.current_node,
        "\n  Foobar",
        at: 'end',
        to: 'caller',
        and_comma: false
      )
      instance.insert_after 'Foobar', to: 'caller'
    end

    it 'parses insert_before' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(NodeMutation).to receive_message_chain(:adapter, :get_start_loc, :column).and_return(2)
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:insert).with(
        instance.current_node,
        "Foobar\n  ",
        at: 'beginning',
        to: 'caller',
        and_comma: false
      )
      instance.insert_before 'Foobar', to: 'caller'
    end

    it 'parses replace_erb_stmt_with_expr' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      action = double
      erb_source = '<% form_for @post do |f| %><% end %>'
      allow(File).to receive(:read).and_return(erb_source)
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:actions).and_return([])
      expect(Rewriter::ReplaceErbStmtWithExprAction).to receive(:new).with(
        instance.current_node,
        erb_source
      ).and_return(action)
      expect(action).to receive(:process)
      instance.replace_erb_stmt_with_expr
    end

    it 'parses replace_with' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:replace_with).with(
        instance.current_node,
        'Foobar'
      )
      instance.replace_with 'Foobar'
    end

    it 'parses replace with' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:replace).with(
        instance.current_node,
        :message,
        with: 'Foobar'
      )
      instance.replace :message, with: 'Foobar'
    end

    it 'parses remove' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:remove).with(
        instance.current_node,
        and_comma: true
      )
      instance.remove and_comma: true
    end

    it 'parses delete' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:delete).with(
        instance.current_node,
        :dot,
        :message,
        and_comma: true
      )
      instance.delete :dot, :message, and_comma: true
    end

    it 'parses wrap with' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:wrap).with(
        instance.current_node,
        with: 'module Foobar'
      )
      instance.wrap with: 'module Foobar'
    end

    it 'parses noop' do
      instance.instance_variable_set(:@current_mutation, double)
      instance.current_node = double
      expect(instance.instance_variable_get(:@current_mutation)).to receive(:noop).with(instance.current_node)
      instance.noop
    end

    it 'parses warn' do
      expect(Rewriter::Warning).to receive(:new).with(instance, 'foobar')
      instance.warn 'foobar'
    end

    it 'adds action' do
      mutation = NodeMutation.new("")
      instance.instance_variable_set(:@current_mutation, mutation)
      action = double
      expect(action).to receive(:process).and_return(action)
      instance.add_action(action)
      expect(mutation.actions).to eq [action]
    end

    describe '#process' do
      let(:rewriter) { Rewriter.new('foo', 'bar') }

      it 'writes new code to file' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/models/post_spec.rb' do
            with_node type: 'send', receiver: 'FactoryGirl', message: 'create' do
              replace_with 'create {{arguments}}'
            end
          end
        input = <<~EOS
          it 'uses factory_girl' do
            user = FactoryGirl.create :user
            post = FactoryGirl.create :post, user: user
            assert post.valid?
          end
        EOS
        output = <<~EOS
          it 'uses factory_girl' do
            user = create :user
            post = create :post, user: user
            assert post.valid?
          end
        EOS
        expect(File).to receive(:read).with('./spec/models/post_spec.rb', encoding: 'UTF-8').and_return(input)
        expect(File).to receive(:write).with('./spec/models/post_spec.rb', output)
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
        input = <<~EOS
          RSpec.configure do |config|
            config.include FactoryGirl::Syntax::Methods
          end
        EOS
        output = <<~EOS
          RSpec.configure do |config|
            config.include FactoryGirl::Syntax::Methods
          end
        EOS
        expect(File).to receive(:read).with('./spec/spec_helper.rb', encoding: 'UTF-8').and_return(input)
        expect(File).not_to receive(:write).with('./spec/spec_helper.rb', output)
        instance.process
      end

      it 'updates file_source and file_ast when writing a file' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/models/post_spec.rb' do
            with_node type: 'send', receiver: 'FactoryGirl', message: 'create' do
              replace_with 'create {{arguments}}'
            end
          end
        input = <<~EOS
          it 'uses factory_girl' do
            user = FactoryGirl.create :user
            post = FactoryGirl.create :post, user: user
            assert post.valid?
          end
        EOS
        output = <<~EOS
          it 'uses factory_girl' do
            user = create :user
            post = create :post, user: user
            assert post.valid?
          end
        EOS
        expect(File).to receive(:read).with('./spec/models/post_spec.rb', encoding: 'UTF-8').and_return(input)
        expect(File).to receive(:write).with('./spec/models/post_spec.rb', output)
        expect(File).to receive(:read).with('./spec/models/post_spec.rb', encoding: 'UTF-8').and_return(output)
        instance.process
        instance.process
        expect(rewriter.affected_files).to be_include('spec/models/post_spec.rb')
      end

      it 'updates erb file' do
        instance =
          Rewriter::Instance.new rewriter, 'app/views/posts/_form.html.erb' do
            with_node type: 'send', receiver: nil, message: 'form_for' do
              replace_erb_stmt_with_expr
            end
          end
        input = <<~EOS
          <% form_for @post do |f| %>
          <% end %>
        EOS
        output = <<~EOS
          <%= form_for @post do |f| %>
          <% end %>
        EOS
        allow(File).to receive(:read).with('./app/views/posts/_form.html.erb', encoding: 'UTF-8').and_return(input)
        expect(File).to receive(:write).with('./app/views/posts/_form.html.erb', output)
        instance.process
      end

      it 'updates haml file' do
        instance =
          Rewriter::Instance.new rewriter, 'app/views/posts/_form.html.haml' do
            with_node node_type: 'ivar' do
              replace_with 'post'
            end
          end
        input = <<~EOS
          = form_for @post do |f|
          = form_for @post do |f|
        EOS
        output = <<~EOS
          = form_for post do |f|
          = form_for post do |f|
        EOS
        allow(File).to receive(:read).with('./app/views/posts/_form.html.haml', encoding: 'UTF-8').and_return(input)
        expect(File).to receive(:write).with('./app/views/posts/_form.html.haml', output)
        instance.process
      end
    end

    describe '#test' do
      let(:rewriter) { Rewriter.new('foo', 'bar') }

      it 'gets actions if afected' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/models/post_spec.rb' do
            with_node type: 'send', receiver: 'FactoryGirl', message: 'create' do
              replace_with 'create {{arguments}}'
            end
          end
        input = <<~EOS
          it 'uses factory_girl' do
            user = FactoryGirl.create :user
            post = FactoryGirl.create :post, user: user
            assert post.valid?
          end
        EOS
        expect(File).to receive(:read).with('./spec/models/post_spec.rb', encoding: 'UTF-8').and_return(input)
        results = instance.test
        expect(results.file_path).to eq 'spec/models/post_spec.rb'
        expect(results.actions).to eq [
          NodeMutation::Struct::Action.new(35, 59, 'create :user'),
          NodeMutation::Struct::Action.new(69, 105, 'create :post, user: user')
        ]
      end

      it 'gets nothing if not affected' do
        instance =
          Rewriter::Instance.new rewriter, 'spec/spec_helper.rb' do
            with_node type: 'block', caller: { receiver: 'RSpec', message: 'configure' } do
              unless_exist_node type: 'send', message: 'include', arguments: ['FactoryGirl::Syntax::Methods'] do
                insert '{{arguments.first}}.include FactoryGirl::Syntax::Methods'
              end
            end
          end
        input = <<~EOS
          RSpec.configure do |config|
            config.include FactoryGirl::Syntax::Methods
          end
        EOS
        expect(File).to receive(:read).with('./spec/spec_helper.rb', encoding: 'UTF-8').and_return(input)
        result = instance.test
        expect(result.file_path).to eq 'spec/spec_helper.rb'
        expect(result.actions).to eq []
      end

      it 'updates erb file' do
        instance =
          Rewriter::Instance.new rewriter, 'app/views/posts/_form.html.erb' do
            with_node type: 'send', receiver: nil, message: 'form_for' do
              replace_erb_stmt_with_expr
            end
          end
        input = <<~EOS
          <% form_for @post do |f| %>
          <% end %>
        EOS
        allow(File).to receive(:read).with('./app/views/posts/_form.html.erb', encoding: 'UTF-8').and_return(input)
        result = instance.test
        expect(result.file_path).to eq 'app/views/posts/_form.html.erb'
        expect(result.actions).to eq [NodeMutation::Struct::Action.new(2, 2, '=')]
      end

      it 'updates haml file' do
        instance =
          Rewriter::Instance.new rewriter, 'app/views/posts/_form.html.haml' do
            with_node node_type: 'ivar' do
              replace_with 'post'
            end
          end
        input = <<~EOS
          = form_for @post do |f|
          = form_for @post do |f|
        EOS
        output = <<~EOS
          = form_for post do |f|
          = form_for post do |f|
        EOS
        allow(File).to receive(:read).with('./app/views/posts/_form.html.haml', encoding: 'UTF-8').and_return(input)
        result = instance.test
        expect(result.file_path).to eq 'app/views/posts/_form.html.haml'
        expect(result.actions).to eq [
          NodeMutation::Struct::Action.new("= form_for ".length, "= form_for @post".length, 'post'),
          NodeMutation::Struct::Action.new(
            "= form_for @post do |f|\n= form_for ".length,
            "= form_for @post do |f|\n= form_for @post".length,
            'post'
          ),
        ]
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

    describe '#wrap_with_quotes' do
      context 'Configuration.single_quote = true' do
        it 'wraps with single quotes' do
          expect(instance.wrap_with_quotes('foobar')).to eq "'foobar'"
        end

        it 'wraps with double quotes if it contains single quote' do
          expect(instance.wrap_with_quotes("foo'bar")).to eq '"foo\'bar"'
        end

        it 'wraps with signle quotes and escapes single quote' do
          expect(instance.wrap_with_quotes("foo'\"bar")).to eq "'foo\\'\"bar'"
        end
      end

      context 'Configuration.single_quote = false' do
        before { Configuration.single_quote = false }
        after { Configuration.single_quote = true }

        it 'wraps with double quotes' do
          expect(instance.wrap_with_quotes('foobar')).to eq '"foobar"'
        end

        it 'wraps with single quotes if it contains double quote' do
          expect(instance.wrap_with_quotes('foo"bar')).to eq "'foo\"bar'"
        end

        it 'wraps with double quotes and escapes double quote' do
          expect(instance.wrap_with_quotes("foo'\"bar")).to eq '"foo\'\\"bar"'
        end
      end
    end

    describe '#add_leading_spaces' do
      it 'adds leading spaces' do
        expect(instance.add_leading_spaces('foo')).to eq '  foo';
        expect(instance.add_leading_spaces('foo', tab_size: 2)).to eq '    foo';
      end
    end
  end
end
