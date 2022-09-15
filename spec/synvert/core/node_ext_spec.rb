# frozen_string_literal: true

require 'spec_helper'

describe Parser::AST::Node do
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
end
