# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter do
    it 'parses description' do
      rewriter =
        Rewriter.new 'group', 'name' do
          description 'rewriter description'
        end
      rewriter.process
      expect(rewriter.description).to eq 'rewriter description'
    end

    it 'parses if_ruby' do
      #stub_const("RUBY_VERSION", '2.0.0')
      rewriter =
        Rewriter.new 'group', 'name' do
          if_ruby '2.0.0'
        end
      rewriter.process
    end

    it 'parses if_gem' do
      expect(Rewriter::GemSpec).to receive(:new).with('synvert', { gte: '1.0.0' })
      rewriter =
        Rewriter.new 'group', 'name' do
          if_gem 'synvert', { gte: '1.0.0' }
        end
      rewriter.process
    end

    describe 'parses within_file' do
      it 'does nothing if if_ruby does not match' do
        stub_const('RUBY_VERSION', '2.0.0')
        expect_any_instance_of(Rewriter::Instance).not_to receive(:process)
        rewriter =
          Rewriter.new 'group', 'name' do
            if_ruby '2.2.3'
            within_file 'config/routes.rb' do
            end
          end
        rewriter.process
      end

      it 'delegates process to instances if if_ruby matches' do
        stub_const('RUBY_VERSION', '2.0.0')
        expect_any_instance_of(Rewriter::Instance).to receive(:process)
        rewriter =
          Rewriter.new 'group', 'name' do
            if_ruby '1.9.3'
            within_file 'config/routes.rb' do
            end
          end
        rewriter.process
      end

      it 'does nothing if if_gem does not match' do
        expect_any_instance_of(Rewriter::GemSpec).to receive(:match?).and_return(false)
        expect_any_instance_of(Rewriter::Instance).not_to receive(:process)
        rewriter =
          Rewriter.new 'group', 'name' do
            if_gem 'synvert', '1.0.0'
            within_file 'config/routes.rb' do
            end
          end
        rewriter.process
      end

      it 'delegates process to instances if if_gem matches' do
        expect_any_instance_of(Rewriter::GemSpec).to receive(:match?).and_return(true)
        expect_any_instance_of(Rewriter::Instance).to receive(:process)
        rewriter =
          Rewriter.new 'group', 'name' do
            if_gem 'synvert', '1.0.0'
            within_file 'config/routes.rb' do
            end
          end
        rewriter.process
      end

      it 'delegates process to instances if if_ruby and if_gem do not exist' do
        expect_any_instance_of(Rewriter::Instance).to receive(:process)
        rewriter =
          Rewriter.new 'group', 'name' do
            within_file 'config/routes.rb' do
            end
          end
        rewriter.process
      end

      it 'does nothing in sandbox mode' do
        expect_any_instance_of(Rewriter::GemSpec).not_to receive(:match?)
        expect_any_instance_of(Rewriter::Instance).not_to receive(:process)
        rewriter =
          Rewriter.new 'group', 'name' do
            if_gem 'synvert', '1.0.0'
            within_file 'config/routes.rb' do
            end
          end
        rewriter.process_with_sandbox
      end
    end

    describe 'parses add_file' do
      it 'creates a new file' do
        rewriter =
          Rewriter.new 'group', 'rewriter2' do
            add_file 'foo.bar', 'FooBar'
          end
        rewriter.process
        expect(File.read('./foo.bar')).to eq 'FooBar'
        FileUtils.rm './foo.bar'
      end

      it 'does nothing in sandbox mode' do
        rewriter =
          Rewriter.new 'group', 'rewriter2' do
            add_file 'foo.bar', 'FooBar'
          end
        rewriter.process_with_sandbox
        expect(File.exist?('./foo.bar')).to be_falsey
      end
    end

    describe 'parses remove_file' do
      it 'removes a file' do
        FileUtils.touch './foo.bar'
        rewriter =
          Rewriter.new 'group', 'rewriter2' do
            remove_file 'foo.bar'
          end
        rewriter.process
        expect(File.exist?('./foo.bar')).to be_falsey
      end

      it 'does nothing if file not exist' do
        rewriter =
          Rewriter.new 'group', 'rewriter2' do
            remove_file 'foo.bar'
          end
        rewriter.process
        expect(File.exist?('./foo.bar')).to be_falsey
      end

      it 'does nothing in sandbox mode' do
        FileUtils.touch './foo.bar'
        rewriter =
          Rewriter.new 'group', 'rewriter2' do
            add_file 'foo.bar', 'FooBar'
          end
        rewriter.process_with_sandbox
        expect(File.exist?('./foo.bar')).to be_truthy
        FileUtils.rm './foo.bar'
      end
    end

    describe 'parses add_snippet' do
      it 'processes the rewritter' do
        rewriter1 = Rewriter.new 'group', 'rewriter1'
        rewriter2 =
          Rewriter.new 'group', 'rewriter2' do
            add_snippet :group, :rewriter1
          end
        expect(rewriter1).to receive(:process)
        rewriter2.process
      end

      it 'adds sub_snippets' do
        rewriter1 = Rewriter.new 'group', 'rewriter1'
        rewriter2 =
          Rewriter.new 'group', 'rewriter2' do
            add_snippet :group, :rewriter1
          end
        expect(rewriter1).to receive(:process)
        rewriter2.process
        expect(rewriter2.sub_snippets).to eq [rewriter1]
      end

      it 'raises RewriterNotFound' do
        rewriter =
          Rewriter.new 'group', 'name' do
            add_snippet :group, :not_exist
          end
        expect { rewriter.process }.to raise_error(RewriterNotFound)
      end
    end

    it 'parses helper_method' do
      rewriter =
        Rewriter.new 'group', 'name' do
          helper_method 'dynamic_helper' do |arg1, arg2|
            'dynamic result'
          end
        end
      rewriter.process
      instance = Rewriter::Instance.new(rewriter, '*.rb')
      expect(instance.dynamic_helper('arg1', 'arg2')).to eq 'dynamic result'
    end

    it 'parses todo' do
      rewriter =
        Rewriter.new 'group', 'name' do
          todo "this rewriter doesn't do blah blah blah"
        end
      rewriter.process
      expect(rewriter.todo).to eq "this rewriter doesn't do blah blah blah"
    end

    describe 'class methods' do
      before :each do
        Rewriter.clear
      end

      it 'registers and fetches' do
        rewriter = Rewriter.new 'group', 'rewriter'
        expect(Rewriter.fetch('group', 'rewriter')).to eq rewriter
      end

      it 'registers and calls rewriter' do
        rewriter = Rewriter.new 'group', 'rewriter'
        expect(rewriter).to receive(:process)
        Rewriter.call 'group', 'rewriter'
      end

      it 'raises RewriterNotFound if rewriter not found' do
        expect { Rewriter.call 'group', 'rewriter' }.to raise_error(RewriterNotFound)
      end

      context 'exist?' do
        it 'returns true if rewriter exists' do
          Rewriter.new 'group', 'rewriter'
          expect(Rewriter.exist?('group', 'rewriter')).to be_truthy
        end

        it 'returns false if rewriter does not exist' do
          expect(Rewriter.exist?('group', 'rewriter')).to be_falsey
        end
      end

      context 'available' do
        it 'lists empty rewriters' do
          expect(Rewriter.availables).to eq({})
        end

        it 'registers and lists all available rewriters' do
          rewriter1 = Rewriter.new 'group', 'rewriter1'
          rewriter2 = Rewriter.new 'group', 'rewriter2'
          expect(Rewriter.availables).to eq({ 'group' => { 'rewriter1' => rewriter1, 'rewriter2' => rewriter2 } })
        end
      end
    end
  end
end
