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

    before { allow(File).to receive(:exist?).with(File.join(ENV['HOME'], '.gem/specs')).and_return(false) }

    it 'returns true if version in Gemfile.lock is greater than definition' do
      expect(File).to receive(:exist?).with('./Gemfile.lock').and_return(true)
      expect(File).to receive(:read).with('./Gemfile.lock').and_return(gemfile_lock_content)
      gem_spec = Rewriter::GemSpec.new('ast', '~> 1.1')
      expect(gem_spec).to be_match
    end

    it 'returns true if version in Gemfile.lock is equal to definition' do
      expect(File).to receive(:exist?).with('./Gemfile.lock').and_return(true)
      expect(File).to receive(:read).with('./Gemfile.lock').and_return(gemfile_lock_content)
      gem_spec = Rewriter::GemSpec.new('ast', '1.1.0')
      expect(gem_spec).to be_match
    end

    it 'returns false if version in Gemfile.lock is less than definition' do
      expect(File).to receive(:exist?).with('./Gemfile.lock').and_return(true)
      expect(File).to receive(:read).with('./Gemfile.lock').and_return(gemfile_lock_content)
      gem_spec = Rewriter::GemSpec.new('ast', '> 1.2.0')
      expect(gem_spec).not_to be_match
    end

    it 'returns false if gem does not exist in Gemfile.lock' do
      expect(File).to receive(:exist?).with('./Gemfile.lock').and_return(true)
      expect(File).to receive(:read).with('./Gemfile.lock').and_return(gemfile_lock_content)
      gem_spec = Rewriter::GemSpec.new('synvert', '1.0.0')
      expect(gem_spec).not_to be_match
    end

    it 'raise Synvert::Core::GemfileLockNotFound if Gemfile.lock does not exist' do
      expect(File).to receive(:exist?).with('./Gemfile.lock').and_return(false)
      gem_spec = Rewriter::GemSpec.new('ast', '1.1.0')
      expect(gem_spec).to be_match
    end
  end
end
