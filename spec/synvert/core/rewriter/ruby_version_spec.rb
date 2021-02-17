# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::RubyVersion do
    it 'returns true if ruby version is greater than 1.9' do
      ruby_version = Rewriter::RubyVersion.new('1.9')
      expect(ruby_version).to be_match
    end

    it 'returns false if ruby version is less than 19.0' do
      ruby_version = Rewriter::RubyVersion.new('19.0')
      expect(ruby_version).not_to be_match
    end
  end
end
