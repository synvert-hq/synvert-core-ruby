require 'spec_helper'

module Synvert::Core
  RSpec.describe Utils do
    describe '.eval_snippet' do
      it 'evals snippet by http url' do
        expect_any_instance_of(URI).to receive(:open).and_return(StringIO.new("Rewriter.new 'group', 'name' do\nend"))
        rewriter = described_class.eval_snippet('http://example.com/rewriter.rb')
        expect(rewriter.group).to eq 'group'
        expect(rewriter.name).to eq 'name'
      end

      it 'adds snippet by file path' do
        expect(File).to receive(:exist?).and_return(true)
        expect(File).to receive(:read).and_return("Rewriter.new 'group', 'name' do\nend")
        rewriter = described_class.eval_snippet('/home/richard/foo/bar.rb')
        expect(rewriter.group).to eq 'group'
        expect(rewriter.name).to eq 'name'
      end

      it 'adds snippet by snippet name' do
        expect(File).to receive(:exist?).and_return(false)
        expect(File).to receive(:read).and_return("Rewriter.new 'group', 'name' do\nend")
        rewriter = described_class.eval_snippet('/home/richard/foo/bar.rb')
        expect(rewriter.group).to eq 'group'
        expect(rewriter.name).to eq 'name'
      end
    end
  end
end