# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::GemSpec do
    let(:gemfile_lock_content) { <<~EOS }
      GEM
        remote: https://rubygems.org/
        specs:
          ast (1.1.0)
          parser (2.1.7)
            ast (~> 1.1)
            slop (~> 3.4, >= 3.4.5)
          rake (10.1.1)
          slop (3.4.7)
    EOS
    let(:gemfile_lock_path) { File.absolute_path('./Gemfile.lock') }
    let(:gemfile_path) { File.absolute_path('./Gemfile') }

    before do
      Configuration.root_path = File.dirname(gemfile_lock_path)
      @original_bundle_gemfile = ENV['BUNDLE_GEMFILE']
      ENV['BUNDLE_GEMFILE'] = gemfile_path
    end

    after do
      Configuration.root_path = nil
      ENV['BUNDLE_GEMFILE'] = @original_bundle_gemfile
    end

    def mock_gemfile_and_lock(gemfile_path, gemfile_lock_path, exists: true)
      if gemfile_path
        expect(File).to receive(:exist?).with(gemfile_path).and_return(true)
      else
        expect(File).to receive(:exist?).with(nil).and_return(false)
      end
      expect(File).to receive(:exist?).with(gemfile_lock_path).and_return(exists)
      expect(File).to receive(:read).with(gemfile_lock_path).and_return(gemfile_lock_content) if exists
    end

    shared_examples 'gem version matching' do |version, expected_match|
      it "returns #{expected_match} for version #{version}" do
        mock_gemfile_and_lock(gemfile_path, gemfile_lock_path)
        gem_spec = Rewriter::GemSpec.new('ast', version)
        expect(gem_spec).send(expected_match ? :to : :not_to, be_match)
      end
    end

    context 'when checking gem versions' do
      include_examples 'gem version matching', '~> 1.1', true
      include_examples 'gem version matching', '1.1.0', true
      include_examples 'gem version matching', '> 1.2.0', false
    end

    it 'returns false if gem does not exist in Gemfile.lock' do
      mock_gemfile_and_lock(gemfile_path, gemfile_lock_path)
      gem_spec = Rewriter::GemSpec.new('synvert', '1.0.0')
      expect(gem_spec).not_to be_match
    end

    it 'returns true if Gemfile.lock does not exist' do
      mock_gemfile_and_lock(gemfile_path, gemfile_lock_path, exists: false)
      gem_spec = Rewriter::GemSpec.new('ast', '1.1.0')
      expect(gem_spec).to be_match
    end

    it 'returns true if Configuration.strict is false' do
      Configuration.strict = false
      gem_spec = Rewriter::GemSpec.new('synvert', '1.0.0')
      expect(gem_spec).to be_match
      Configuration.strict = true
    end

    describe 'gemfile lock name behavior' do
      it 'uses default Gemfile.lock when BUNDLE_GEMFILE is not set' do
        ENV['BUNDLE_GEMFILE'] = nil
        mock_gemfile_and_lock(nil, gemfile_lock_path)
        gem_spec = Rewriter::GemSpec.new('ast', '1.1.0')
        expect(gem_spec).to be_match
      end

      it 'uses custom Gemfile lock name when BUNDLE_GEMFILE is set' do
        custom_gemfile = File.absolute_path('./Gemfile.next')
        custom_gemfile_lock_path = File.absolute_path('./Gemfile.next.lock')
        ENV['BUNDLE_GEMFILE'] = custom_gemfile
        mock_gemfile_and_lock(custom_gemfile, custom_gemfile_lock_path)
        gem_spec = Rewriter::GemSpec.new('ast', '1.1.0')
        expect(gem_spec).to be_match
      end
    end
  end
end
