require 'spec_helper'

module Synvert::Core
  RSpec.describe Utils do
    describe '.eval_snippet' do
      context "by http url" do
        it 'evals snippet' do
          expect(described_class).to receive(:remote_snippet_exists?).with(URI.parse('http://example.com/rewriter.rb')).and_return(true)
          expect_any_instance_of(URI::HTTP).to receive(:open).and_return(StringIO.new("Rewriter.new 'group', 'name' do\nend"))
          rewriter = described_class.eval_snippet('http://example.com/rewriter.rb')
          expect(rewriter.group).to eq 'group'
          expect(rewriter.name).to eq 'name'
        end

        it 'evals github url' do
          expect(described_class).to receive(:remote_snippet_exists?).with(URI.parse('https://raw.githubusercontent.com/synvert-hq/synvert-snippets-ruby/main/lib/bundler/use_shortcut_git_source.rb')).and_return(true)
          expect_any_instance_of(URI::HTTP).to receive(:open).and_return(StringIO.new("Rewriter.new 'group', 'name' do\nend"))
          rewriter = described_class.eval_snippet('https://github.com/synvert-hq/synvert-snippets-ruby/blob/main/lib/bundler/use_shortcut_git_source.rb')
          expect(rewriter.group).to eq 'group'
          expect(rewriter.name).to eq 'name'
        end

        it 'evals gist url' do
          expect(described_class).to receive(:remote_snippet_exists?).with(URI.parse('https://gist.githubusercontent.com/flyerhzm/6b868cf6cceba0e2fa253f1936acf1f6/raw')).and_return(true)
          expect_any_instance_of(URI::HTTP).to receive(:open).and_return(StringIO.new("Rewriter.new 'group', 'name' do\nend"))
          rewriter = described_class.eval_snippet('https://gist.github.com/flyerhzm/6b868cf6cceba0e2fa253f1936acf1f6')
          expect(rewriter.group).to eq 'group'
          expect(rewriter.name).to eq 'name'
        end

        it 'raises error' do
          expect(described_class).to receive(:remote_snippet_exists?).and_return(false)
          expect do
            described_class.eval_snippet('http://example.com/rewriter.rb')
          end.to raise_error(Errors::SnippetNotFound)
        end
      end

      context 'by file path' do
        it 'evals snippet' do
          expect(File).to receive(:exist?).and_return(true)
          expect(File).to receive(:read).and_return("Rewriter.new 'group', 'name' do\nend")
          rewriter = described_class.eval_snippet('/home/richard/foo/bar.rb')
          expect(rewriter.group).to eq 'group'
          expect(rewriter.name).to eq 'name'
        end
      end

      context 'by snippet name' do
        it 'evals snippet as file' do
          expect(File).to receive(:exist?).with("group/name").and_return(false)
          expect(described_class).to receive(:default_snippets_home).and_return('/home/richard/.synvert-ruby')
          expect(File).to receive(:exist?).with("/home/richard/.synvert-ruby/lib/group/name.rb").and_return(true)
          expect(File).to receive(:read).and_return("Rewriter.new 'group', 'name' do\nend")
          rewriter = described_class.eval_snippet('group/name')
          expect(rewriter.group).to eq 'group'
          expect(rewriter.name).to eq 'name'
        end

        it 'evals snippet as github url' do
          expect(File).to receive(:exist?).with("group/name").and_return(false)
          expect(described_class).to receive(:default_snippets_home).and_return('/home/richard/.synvert-ruby')
          expect(File).to receive(:exist?).with("/home/richard/.synvert-ruby/lib/group/name.rb").and_return(false)
          expect(described_class).to receive(:remote_snippet_exists?).with(URI.parse("https://raw.githubusercontent.com/synvert-hq/synvert-snippets-ruby/main/lib/group/name.rb")).and_return(true)
          expect_any_instance_of(URI::HTTP).to receive(:open).and_return(StringIO.new("Rewriter.new 'group', 'name' do\nend"))
          rewriter = described_class.eval_snippet('group/name')
          expect(rewriter.group).to eq 'group'
          expect(rewriter.name).to eq 'name'
        end
      end
    end

    describe '.glob' do
      before do
        Configuration.only_paths = []
        Configuration.skip_paths = []
        Configuration.respect_gitignore = false
      end

      context 'Configuration.respect_gitignore is false' do
        it 'gets all files' do
          expect(Dir).to receive(:glob).with('**/*.rb').and_return(
            [
              'app/models/post.rb',
              'app/controllers/posts_controller.rb'
            ]
          )
          expect(described_class.glob(['**/*.rb'])).to eq(['app/models/post.rb', 'app/controllers/posts_controller.rb'])
        end
      end

      context 'Configuration.respect_gitignore is true' do
        before do
          Configuration.respect_gitignore = true
        end

        it 'correctly filters out ignored files' do
          file_patterns = ["**/*.rb"]
          all_files = ["app/models/post.rb", "app/controllers/posts_controller.rb", "app/controllers/temp.tmp"]
          not_ignored_files = ["app/models/post.rb", "app/controllers/posts_controller.rb"]
          command_output = "app/controllers/temp.tmp\n"

          allow(Open3).to receive(:popen3).with('git check-ignore --stdin').and_yield(
            instance_double(IO, puts: nil, close: nil),
            StringIO.new(command_output),
            StringIO.new(''),
            instance_double(Process::Waiter, value: instance_double(Process::Status, success?: true))
          )
          allow(Dir).to receive(:glob).and_return(all_files)

          expect(described_class.glob(file_patterns)).to match_array(not_ignored_files)
        end
      end

      it 'filters only paths' do
        Configuration.only_paths = ['app/models']
        expect(Dir).to receive(:glob).with('**/*.rb').and_return(
          [
            'app/models/post.rb',
            'app/controllers/posts_controller.rb'
          ]
        )
        expect(described_class.glob(['**/*.rb'])).to eq(['app/models/post.rb'])
      end

      it 'skip files' do
        Configuration.skip_paths = ['app/controllers/**/*']
        expect(Dir).to receive(:glob).with('**/*.rb').and_return(
          [
            'app/models/post.rb',
            'app/controllers/posts_controller.rb'
          ]
        )
        expect(Dir).to receive(:glob).with('app/controllers/**/*').and_return(['app/controllers/posts_controller.rb'])
        expect(described_class.glob(['**/*.rb'])).to eq(['app/models/post.rb'])
      end
    end
  end
end
