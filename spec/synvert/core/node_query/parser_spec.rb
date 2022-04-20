require 'spec_helper'

module Synvert::Core::NodeQuery
  RSpec.describe Parser do
    let(:parser) { described_class.new }

    def assert_parser(source)
      expect(parser.parse(source).to_s).to eq source
    end

    it 'parses one selector' do
      source = '.send[message=:create]'
      assert_parser(source)
    end

    it 'parses two selectors' do
      source = '.class[name="Synvert"] .def[name="foobar"]'
      assert_parser(source)
    end

    it 'parses child selector' do
      source = '.class[name="Synvert"] > .def[name="foobar"]'
      assert_parser(source)
    end

    it 'parses multiple attributes' do
      source = '.send[receiver=nil][message=:create]'
      assert_parser(source)
    end

    it 'parses nested attributes' do
      source = '.send[receiver.message=:create]'
      assert_parser(source)
    end

    it 'parses selector value' do
      source = '.send[receiver=.send[message=:create]]'
      assert_parser(source)
    end
  end
end