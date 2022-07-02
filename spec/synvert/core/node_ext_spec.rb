# frozen_string_literal: true

require 'spec_helper'

describe Parser::AST::Node do
  describe '#match?' do
    it 'matches class name' do
      source = 'class Synvert; end'
      node = parse(source)
      expect(node).to be_match(type: 'class', name: 'Synvert')
    end

    it 'matches message with regexp' do
      source = 'User.find_by_login(login)'
      node = parse(source)
      expect(node).to be_match(type: 'send', message: /^find_by_/)
    end

    it 'matches arguments with symbol' do
      source = 'params[:user]'
      node = parse(source)
      expect(node).to be_match(type: 'send', receiver: 'params', message: '[]', arguments: [:user])
    end

    it 'matches pair key with symbol' do
      source = '{ type: :model }'
      node = parse(source).children[0]
      expect(node).to be_match(type: 'pair', key: :type)
    end

    it 'matches assign number' do
      source = 'at_least(0)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: [0])
    end

    it 'matches assign float' do
      source = 'at_least(1.5)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: [1.5])
    end

    it 'matches arguments with string' do
      source = 'params["user"]'
      node = parse(source)
      expect(node).to be_match(type: 'send', receiver: 'params', message: '[]', arguments: ['user'])
    end

    it 'matches arguments with string 2' do
      source = 'params["user"]'
      node = parse(source)
      expect(node).to be_match(type: 'send', receiver: 'params', message: '[]', arguments: ["'user'"])
    end

    it 'matches arguments with string 3' do
      source = "{ notice: 'Welcome' }"
      node = parse(source)
      expect(node).to be_match(type: 'hash', notice_value: "'Welcome'")
    end

    it 'matches arguments any' do
      source = 'config.middleware.insert_after ActiveRecord::QueryCache, Lifo::Cache, page_cache: false'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: { any: 'Lifo::Cache' })
    end

    it 'matches arguments with nested hash' do
      source = '{ user_id: user.id }'
      node = parse(source)
      expect(node).to be_match(
        type: 'hash',
        user_id_value: {
          type: 'send',
          receiver: { type: 'send', message: 'user' },
          message: 'id'
        }
      )
    end

    it 'matches arguments contain' do
      source = 'def slow(foo, bar, &block); end'
      node = parse(source)
      expect(node).to be_match(type: 'def', arguments: { contain: '&block' })
    end

    it 'matches not' do
      source = 'class Synvert; end'
      node = parse(source)
      expect(node).not_to be_match(type: 'class', name: { not: 'Synvert' })
    end

    it 'matches in' do
      source = 'FactoryBot.create(:user)'
      node = parse(source)
      expect(node).to be_match(type: 'send', message: { in: %i[create build] })
    end

    it 'matches not_in' do
      source = 'FactoryBot.create(:user)'
      node = parse(source)
      expect(node).not_to be_match(type: 'send', message: { not_in: %i[create build] })
    end

    it 'matches gt' do
      source = 'foobar(foo, bar)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: { size: { gt: 1 } })
      expect(node).not_to be_match(type: 'send', arguments: { size: { gt: 2 } })
    end

    it 'matches gte' do
      source = 'foobar(foo, bar)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: { size: { gte: 2 } })
      expect(node).not_to be_match(type: 'send', arguments: { size: { gte: 3 } })
    end

    it 'matches lt' do
      source = 'foobar(foo, bar)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: { size: { lt: 3 } })
      expect(node).not_to be_match(type: 'send', arguments: { size: { lt: 2 } })
    end

    it 'matches lte' do
      source = 'foobar(foo, bar)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: { size: { lte: 2 } })
      expect(node).not_to be_match(type: 'send', arguments: { size: { lte: 1 } })
    end
  end

  describe '#strip_curly_braces' do
    context 'hash node' do
      it 'removes curly braces' do
        node = parse("{ foo: 'bar' }")
        expect(node.strip_curly_braces).to eq("foo: 'bar'")
      end
    end

    context 'other node' do
      it 'do nothing' do
        node = parse("'foobar'")
        expect(node.strip_curly_braces).to eq("'foobar'")
      end
    end
  end

  describe '#wrap_curly_braces' do
    context 'hash node' do
      it 'adds curly braces' do
        node = parse("test(foo: 'bar')").arguments.first
        expect(node.to_source).to eq("foo: 'bar'")
        expect(node.wrap_curly_braces).to eq("{ foo: 'bar' }")
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse("'foobar'")
        expect(node.wrap_curly_braces).to eq("'foobar'")
      end
    end
  end

  describe '#to_single_quote' do
    context 'str node' do
      it 'converts double quote to single quote' do
        node = parse('"foobar"')
        expect(node.to_source).to eq '"foobar"'
        expect(node.to_single_quote).to eq "'foobar'"
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse(':foobar')
        expect(node.to_single_quote).to eq ':foobar'
      end
    end
  end

  describe '#to_symbol' do
    context 'str node' do
      it 'converts string to symbol' do
        node = parse("'foobar'")
        expect(node.to_symbol).to eq ':foobar'
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse(':foobar')
        expect(node.to_symbol).to eq ':foobar'
      end
    end
  end

  describe '#to_string' do
    context 'sym node' do
      it 'converts symbol to string' do
        node = parse(':foobar')
        expect(node.to_string).to eq 'foobar'
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse("'foobar'")
        expect(node.to_string).to eq "'foobar'"
      end
    end
  end

  describe '#to_lambda_literal' do
    context 'lambda node' do
      it 'converts to lambda literal without arguments' do
        node = parse('lambda { foobar }')
        expect(node.to_lambda_literal).to eq('-> { foobar }')
      end

      it 'converts to lambda literal with arguments' do
        node = parse('lambda { |x, y| foobar }')
        expect(node.to_lambda_literal).to eq('->(x, y) { foobar }')
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse(':foobar')
        expect(node.to_lambda_literal).to eq ':foobar'
      end
    end
  end

  describe '#to_hash' do
    it 'gets hash' do
      node = parse(<<~EOS)
        class Synvert
          def foobar(foo, bar)
            { foo => bar }
          end
        end
      EOS
      expect(node.to_hash).to eq(
        {
          type: :class,
          parent_class: nil,
          name: {
            type: :const,
            parent_const: nil,
            name: :Synvert
          },
          body: [
            {
              type: :def,
              name: :foobar,
              arguments: [
                { type: :arg, name: :foo },
                { type: :arg, name: :bar }
              ],
              body: [
                {
                  type: :hash,
                  pairs: {
                    type: :pair,
                    key: { type: :lvar, name: :foo },
                    value: { type: :lvar, name: :bar }
                  }
                }
              ]
            }
          ]
        }
      )
    end
  end
end
