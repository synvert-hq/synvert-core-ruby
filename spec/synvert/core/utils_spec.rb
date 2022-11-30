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

        it 'raises error' do
          expect(described_class).to receive(:remote_snippet_exists?).and_return(false)
          expect do
            described_class.eval_snippet('http://example.com/rewriter.rb')
          end.to raise_error(SnippetNotFoundError)
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
          expect(described_class).to receive(:remote_snippet_exists?).with(URI.parse("https://raw.githubusercontent.com/xinminlabs/synvert-snippets-ruby/main/lib/group/name.rb")).and_return(true)
          expect_any_instance_of(URI::HTTP).to receive(:open).and_return(StringIO.new("Rewriter.new 'group', 'name' do\nend"))
          rewriter = described_class.eval_snippet('group/name')
          expect(rewriter.group).to eq 'group'
          expect(rewriter.name).to eq 'name'
        end
      end
    end
  end
end