require 'spec_helper'

module Synvert::Core
  describe Configuration do
    it 'sets / gets' do
      Configuration.instance.set :key, 'value'
      expect(Configuration.instance.get(:key)).to eq 'value'
    end
  end
end
