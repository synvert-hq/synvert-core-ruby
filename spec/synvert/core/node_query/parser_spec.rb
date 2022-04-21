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
      source = '.class[name=Synvert] .def[name="foobar"]'
      assert_parser(source)
    end

    it 'parses child selector' do
      source = '.class[name=Synvert] > .def[name="foobar"]'
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

    it 'parses not equal operator' do
      source = '.send[receiver=.send[message!=:create]]'
      assert_parser(source)
    end

    it 'parses greater than operator' do
      source = '.send[receiver=.send[arguments.size>1]]'
      assert_parser(source)
    end

    it 'parses greater than or equal operator' do
      source = '.send[receiver=.send[arguments.size>=1]]'
      assert_parser(source)
    end

    it 'parses less than operator' do
      source = '.send[receiver=.send[arguments.size<1]]'
      assert_parser(source)
    end

    it 'parses less than or equal operator' do
      source = '.send[receiver=.send[arguments.size<=1]]'
      assert_parser(source)
    end

    describe '#query_nodes' do
      let(:node) {
        parse(<<~EOS)
          class Synvert
            def foo
              FactoryBot.create(:user, name: 'foo')
            end

            def bar
              FactoryGirl.create(:user, name: 'bar')
            end

            def foobar
              { a: a, b: b }
            end
          end
        EOS
      }

      it 'matches class node' do
        expression = parser.parse('.class[name=Synvert]')
        expect(expression.query_nodes(node)).to eq [node]
      end

      it 'matches def node' do
        expression = parser.parse('.def')
        expect(expression.query_nodes(node)).to eq node.body
      end

      it 'matches descendant node' do
        expression = parser.parse('.class .send[message=:create]')
        expect(expression.query_nodes(node)).to eq [node.body.first.children.last, node.body.second.children.last]
      end

      it 'matches child node' do
        expression = parser.parse('.def > .send[message=:create]')
        expect(expression.query_nodes(node)).to eq [node.body.first.children.last, node.body.second.children.last]
      end

      it 'matches next sibling node' do
        expression = parser.parse('.def[name=foo] + .def[name=bar]')
        expect(expression.query_nodes(node)).to eq [node.body.second]
      end

      it 'matches sebsequent sibling node' do
        expression = parser.parse('.def[name=foo] ~ .def[name=foobar]')
        expect(expression.query_nodes(node)).to eq [node.body.last]
      end

      it 'matches arguments.size' do
        expression = parser.parse('.send[arguments.size=2]')
        expect(expression.query_nodes(node)).to eq [node.body.first.children.last, node.body.second.children.last]
      end

      it 'matches arguments' do
        expression = parser.parse('.send[arguments=[size=2][first=.sym][last=.hash]]')
        expect(expression.query_nodes(node)).to eq [node.body.first.children.last, node.body.second.children.last]
      end

      it 'matches regexp value' do
        expression = parser.parse('.def[name=/foo/]')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.last]
      end

      it 'matches attribute value' do
        expression = parser.parse('.pair[key={{value}}]')
        expect(expression.query_nodes(node)).to eq node.body.last.body.first.children
      end
    end
  end
end