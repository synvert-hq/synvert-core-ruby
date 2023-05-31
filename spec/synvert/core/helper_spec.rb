# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  RSpec.describe Helper do
    describe 'class methods' do
      before :each do
        described_class.clear
      end

      it 'registers and fetches' do
        helper = described_class.new 'helper' do; end
        expect(described_class.fetch('helper')).to eq helper
      end

      context 'available' do
        it 'lists empty helpers' do
          expect(described_class.availables).to eq({})
        end

        it 'registers and lists all available helpers' do
          helper1 = Helper.new 'helper1' do; end
          helper2 = Helper.new 'helper2' do; end
          expect(Helper.availables).to eq({ 'helper1' => helper1, 'helper2' => helper2 })
        end
      end
    end
  end
end
