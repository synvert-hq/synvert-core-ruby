require 'spec_helper'

def assert_parser(source)
  expect(parser.parse(source).to_s).to eq source
end

module Synvert::Core::NodeQuery
  RSpec.describe Parser do
    let(:parser) { described_class.new }

    describe '#toString' do
      it 'parses one selector' do
        source = '.send[message=:create]'
        assert_parser(source)
      end

      it 'parses two selectors' do
        source = '.class[name=Synvert] .def[name="foobar"]'
        assert_parser(source)
      end

      it 'parses three selectors' do
        source = '.class[name=Synvert] .def[name="foobar"] .send[message=create]'
        assert_parser(source)
      end

      it 'parses child selector' do
        source = '.class[name=Synvert] > .def[name="foobar"]'
        assert_parser(source)
      end

      it 'parses scope' do
        source = '.block <body> > .send'
        assert_parser(source)
      end

      it 'parses :first-child' do
        source = '.class .def:first-child'
        assert_parser(source)
      end

      it 'parses :last-child' do
        source = '.class .def:last-child'
        assert_parser(source)
      end

      it 'parses :nth-child(n)' do
        source = '.class .def:nth-child(2)'
        assert_parser(source)
      end

      it 'parses :nth-last-child(n)' do
        source = '.class .def:nth-last-child(2)'
        assert_parser(source)
      end

      it 'parses :has selector' do
        source = '.class :has(> .def)'
        assert_parser(source)
      end

      it 'parses :not_has selector' do
        source = '.class :not_has(> .def)'
        assert_parser(source)
      end

      it 'parses root :has selector' do
        source = ':has(.def)'
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

      it 'parses start with operator' do
        source = '.def[name^=synvert]'
        assert_parser(source)
      end

      it 'parses end with operator' do
        source = '.def[name$=synvert]'
        assert_parser(source)
      end

      it 'parses contain operator' do
        source = '.def[name*=synvert]'
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

      it 'parses in operator' do
        source = '.def[name in (foo bar)]'
        assert_parser(source)
      end

      it 'parses not_in operator' do
        source = '.def[name not in (foo bar)]'
        assert_parser(source)
      end

      it 'parses includes operator' do
        source = '.def[arguments includes &block]'
        assert_parser(source)
      end

      it 'parses empty string' do
        source = '.send[arguments.first=""]'
        assert_parser(source)
      end

      it 'parses []=' do
        source = '.send[message=[]=]'
        assert_parser(source)
      end

      it 'parses :[]' do
        source = '.send[message=:[]]'
        assert_parser(source)
      end
    end

    describe '#query_nodes' do
      let(:node) {
        parse(<<~EOS)
          class Synvert
            def foo
              FactoryBot.create(:user, name: 'foo')
            end

            def bar
              FactoryBot.create(:user, name: 'bar')
            end

            def foobar(a, b)
              { a: a, b: b }
              arr[index]
              arr[index] = value
              nil?
              call('')
            end
          end
        EOS
      }

      let(:test_node) {
        parse(<<~EOS)
          RSpec.describe Synvert do
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

      it 'matches first def node' do
        expression = parser.parse('.def:first-child')
        expect(expression.query_nodes(node)).to eq [node.body.first]
      end

      it 'matches nested first node' do
        expression = parser.parse('.def[arguments.size=0] .send:first-child')
        expect(expression.query_nodes(node)).to eq [node.body.first.body.first, node.body.second.body.first]
      end

      it 'matches last def node' do
        expression = parser.parse('.def:last-child')
        expect(expression.query_nodes(node)).to eq [node.body.last]
      end

      it 'matches nth-child node' do
        expression = parser.parse('.def:nth-child(2)')
        expect(expression.query_nodes(node)).to eq [node.body.second]
      end

      it 'matches nth-last-child node' do
        expression = parser.parse('.def:nth-last-child(2)')
        expect(expression.query_nodes(node)).to eq [node.body[-2]]
      end

      it 'matches start with' do
        expression = parser.parse('.def[name^=foo]')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.last]
      end

      it 'matches end with' do
        expression = parser.parse('.def[name$=bar]')
        expect(expression.query_nodes(node)).to eq [node.body.second, node.body.last]
      end

      it 'matches contain' do
        expression = parser.parse('.def[name*=oob]')
        expect(expression.query_nodes(node)).to eq [node.body.last]
      end

      it 'matches not equal' do
        expression = parser.parse('.def[name!=foobar]')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.second]
      end

      it 'matches in' do
        expression = parser.parse('.def[name IN (foo bar)]')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.second]
      end

      it 'matches not in' do
        expression = parser.parse('.def[name NOT IN (foo bar)]')
        expect(expression.query_nodes(node)).to eq [node.body.last]
      end

      it 'matches includes' do
        expression = parser.parse('.def[arguments INCLUDES a]')
        expect(expression.query_nodes(node)).to eq [node.body.last]
      end

      it 'matches equal array' do
        expression = parser.parse('.def[arguments=(a b)]')
        expect(expression.query_nodes(node)).to eq [node.body.last]

        expression = parser.parse('.def[arguments=(b a)]')
        expect(expression.query_nodes(node)).to eq []
      end

      it 'matches not equal array' do
        expression = parser.parse('.def[arguments!=(a b)]')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.second]

        expression = parser.parse('.def[arguments!=(b a)]')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.second, node.body.last]
      end

      it 'matches descendant node' do
        expression = parser.parse('.class .send[message=:create]')
        expect(expression.query_nodes(node)).to eq [node.body.first.body.last, node.body.second.body.last]
      end

      it 'matches three level descendant node' do
        expression = parser.parse('.class .def .send[message=:create]')
        expect(expression.query_nodes(node)).to eq [node.body.first.body.last, node.body.second.body.last]
      end

      it 'matches child node' do
        expression = parser.parse('.def > .send[message=:create]')
        expect(expression.query_nodes(node)).to eq [node.body.first.body.last, node.body.second.body.last]
      end

      it 'matches next sibling node' do
        expression = parser.parse('.def[name=foo] + .def[name=bar]')
        expect(expression.query_nodes(node)).to eq [node.body.second]
      end

      it 'matches sebsequent sibling node' do
        expression = parser.parse('.def[name=foo] ~ .def[name=foobar]')
        expect(expression.query_nodes(node)).to eq [node.body.last]
      end

      it 'matches goto scope' do
        expression = parser.parse('.def <body> > .send[message=:create]')
        expect(expression.query_nodes(node)).to eq [node.body.first.body.last, node.body.second.body.last]

        expression = parser.parse('.def <body> .send[message=:create]')
        expect(expression.query_nodes(node)).to eq [node.body.first.body.last, node.body.second.body.last]
      end

      it 'matches multiple goto scope' do
        expression = parser.parse('.block <caller.arguments> .const[name=Synvert]')
        expect(expression.query_nodes(test_node)).to eq [test_node.caller.arguments.first]
      end

      it 'matches has selector' do
        expression = parser.parse('.def:has(> .send[receiver=FactoryBot])')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.second]
      end

      it 'matches not_has selector' do
        expression = parser.parse('.def:not_has(> .send[receiver=FactoryBot])')
        expect(expression.query_nodes(node)).to eq [node.body.last]
      end

      it 'matches root has selector' do
        expression = parser.parse(':has(.def[name=foobar])')
        expect(expression.query_nodes(node)).to eq [node]
      end

      it 'matches arguments.size' do
        expression = parser.parse('.def .send[arguments.size=2]')
        expect(expression.query_nodes(node)).to eq [
          node.body.first.body.last,
          node.body.second.body.last,
          node.body.third.body.third
        ]
        expression = parser.parse('.def .send[arguments.size>2]')
        expect(expression.query_nodes(node)).to eq []
        expression = parser.parse('.def .send[arguments.size>=2]')
        expect(expression.query_nodes(node)).to eq [
          node.body.first.body.last,
          node.body.second.body.last,
          node.body.third.body.third
        ]
      end

      it 'matches arguments' do
        expression = parser.parse('.send[arguments.size=2][arguments.first=.sym][arguments.last=.hash]')
        expect(expression.query_nodes(node)).to eq [node.body.first.body.last, node.body.second.body.last]
      end

      it 'matches regexp value' do
        expression = parser.parse('.def[name=~/foo/]')
        expect(expression.query_nodes(node)).to eq [node.body.first, node.body.last]
        expression = parser.parse('.def[name!~/bar/]')
        expect(expression.query_nodes(node)).to eq [node.body.first]
      end

      it 'matches attribute value' do
        expression = parser.parse('.pair[key={{value}}]')
        expect(expression.query_nodes(node)).to eq node.body.last.body.first.children
      end

      it 'matches []' do
        expression = parser.parse('.send[message=[]]')
        expect(expression.query_nodes(node)).to eq [node.body.last.body.second]
      end

      it 'matches []=' do
        expression = parser.parse('.send[message=:[]=]')
        expect(expression.query_nodes(node)).to eq [node.body.last.body.third]
      end

      it 'matches nil and nil?' do
        expression = parser.parse('.send[receiver=nil][message=nil?]')
        expect(expression.query_nodes(node)).to eq [node.body.last.body.fourth]
      end

      it 'matches empty string' do
        expression = parser.parse('.send[message=call][arguments.first=""]')
        expect(expression.query_nodes(node)).to eq [node.body.last.body.last]
      end
    end
  end
end
