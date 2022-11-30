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
      expect(Rewriter::RubyVersion).to receive(:new).with('2.0.0')
      rewriter =
        Rewriter.new 'group', 'name' do
          if_ruby '2.0.0'
        end
      rewriter.process
    end

    it 'parses if_gem' do
      expect(Rewriter::GemSpec).to receive(:new).with('synvert', '>= 1.0.0')
      rewriter =
        Rewriter.new 'group', 'name' do
          if_gem 'synvert', '>= 1.0.0'
        end
      rewriter.process
    end

    describe '#process' do
      it 'rewrites the file' do
        rewriter = Rewriter.new('group', 'name') do
          within_files '**/*.rb' do
            with_node node_type: 'class', name: 'Foobar' do
              replace :name, with: 'Synvert'
            end
          end
        end
        input = "class Foobar\nend"
        output = "class Synvert\nend"
        FakeFS do
          File.write("code.rb", input)
          rewriter.process
          expect(File.read("code.rb")).to eq output
        end
      end
    end

    describe '#test' do
      it 'gets test results' do
        rewriter = Rewriter.new('group', 'name') do
          within_files '**/*.rb' do
            with_node node_type: 'class', name: 'Foobar' do
              replace :name, with: 'Synvert'
            end
          end
        end
        input = "class Foobar\nend"
        FakeFS do
          File.write("code.rb", input)
          results = rewriter.test
          expect(results[0].file_path).to eq '/code.rb'
          expect(results[0].affected?).to be_truthy
          expect(results[0].conflicted?).to be_falsey
          expect(results[0].actions).to eq [OpenStruct.new(start: 6, end: 12, new_code: 'Synvert')]
        end
      end
    end

    describe 'parses within_file' do
      it 'does nothing if if_ruby does not match' do
        expect(File).to receive(:exist?).with('./.ruby-version').and_return(true)
        expect(File).to receive(:read).with('./.ruby-version').and_return('2.0.0')
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
        expect(File).to receive(:exist?).with('./.ruby-version').and_return(true)
        expect(File).to receive(:read).with('./.ruby-version').and_return('2.0.0')
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
            add_snippet 'group', 'rewriter1'
          end
        expect(rewriter1).to receive(:process)
        rewriter2.process
      end

      it 'adds sub_snippets' do
        rewriter1 = Rewriter.new 'group', 'rewriter1'
        rewriter2 =
          Rewriter.new 'group', 'rewriter2' do
            add_snippet 'group', 'rewriter1'
          end
        expect(rewriter1).to receive(:process)
        rewriter2.process
        expect(rewriter2.sub_snippets).to eq [rewriter1]
      end

      it 'adds snippet by http url' do
        expect(Utils).to receive(:remote_snippet_exists?).with(URI.parse('http://synvert.net/foo/bar.rb')).and_return(true)
        expect_any_instance_of(URI::HTTP).to receive(:open).and_return(StringIO.new("Rewriter.new 'group', 'sub_rewriter' do\nend"))
        rewriter = Rewriter.new 'group', 'rewriter' do
          add_snippet 'http://synvert.net/foo/bar.rb'
        end
        rewriter.process
        expect(Rewriter.fetch('group', 'sub_rewriter')).not_to be_nil
      end

      it 'adds snippet by file path' do
        expect(File).to receive(:exist?).and_return(true)
        expect(File).to receive(:read).and_return("Rewriter.new 'group', 'sub_rewriter' do\nend")
        rewriter = Rewriter.new 'group', 'rewriter' do
          add_snippet '/home/richard/foo/bar.rb'
        end
        rewriter.process
        expect(Rewriter.fetch('group', 'sub_rewriter')).not_to be_nil
      end
    end

    it 'parses helper_method' do
      rewriter =
        Rewriter.new 'group', 'name' do
          helper_method 'dynamic_helper' do |_arg1, _arg2|
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

    it 'parses redo_until_no_change' do
      rewriter =
        Rewriter.new 'group', 'name' do
          redo_until_no_change
        end
      rewriter.process
      expect(rewriter.instance_variable_get('@redo_until_no_change')).to be_truthy
    end

    describe 'class methods' do
      before :each do
        Rewriter.clear
      end

      it 'registers and fetches' do
        rewriter = Rewriter.new 'group', 'rewriter'
        expect(Rewriter.fetch('group', 'rewriter')).to eq rewriter
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
