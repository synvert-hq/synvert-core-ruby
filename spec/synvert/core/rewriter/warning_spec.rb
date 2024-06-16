# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::Warning do
    subject {
      Rewriter::Warning.new('app/test.rb', 2, 'remove debugger')
    }

    it 'gets message with filename and line number' do
      expect(subject.message).to eq 'app/test.rb#2: remove debugger'
    end
  end
end
