# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::RubyVersion do
    before do
      allow(File).to receive(:exist?).with('./.ruby-version').and_return(true)
      allow(File).to receive(:read).with('./.ruby-version').and_return('3.0.0')
    end

    it 'returns true if ruby version is greater than 1.9' do
      ruby_version = Rewriter::RubyVersion.new('1.9')
      expect(ruby_version).to be_match
    end

    it 'returns false if ruby version is less than 19.0' do
      ruby_version = Rewriter::RubyVersion.new('19.0')
      expect(ruby_version).not_to be_match
    end

    it 'returns true if strict Configuration is false' do
      Configuration.strict = false
      ruby_version = Rewriter::RubyVersion.new('19.0')
      expect(ruby_version).to be_match
      Configuration.strict = true
    end

    it 'returns true if ruby version is ruby-3.0.0\n' do
      allow(File).to receive(:read).with('./.ruby-version').and_return("ruby-3.0.0\n")
      ruby_version = Rewriter::RubyVersion.new('1.9')
      expect(ruby_version).to be_match
    end
  end
end
