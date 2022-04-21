require 'spec_helper'
require 'oedipus_lex'

module Synvert::Core::NodeQuery
  RSpec.describe Lexer do
    let(:lexer) { described_class.new }

    def assert_tokens(source, expected_tokens)
      lexer.parse(source)
      tokens = []
      while token = lexer.next_token
        tokens << token
      end
      expect(tokens).to eq expected_tokens
    end

    context 'ast node type' do
      it 'matches node type' do
        source = '.send'
        expected_tokens = [
          [:tNODE_TYPE, "send"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'attribute value' do
      it 'matches =' do
        source = '.send[message=create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "message"],
          [:tEQUAL, "="],
          [:tIDENTIFIER, "create"],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches nil' do
        source = '.send[receiver=nil]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "receiver"],
          [:tEQUAL, "="],
          [:tNIL, nil],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches string' do
        source = '.send[message="create"]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "message"],
          [:tEQUAL, "="],
          [:tSTRING, "create"],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches symbol' do
        source = '.send[message=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "message"],
          [:tEQUAL, "="],
          [:tSYMBOL, :create],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches integer' do
        source = '[value=1]'
        expected_tokens = [
          [:tLEFT_SQUARE, "["],
          [:tKEY, "value"],
          [:tEQUAL, "="],
          [:tINTEGER, 1],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches float' do
        source = '.send[value=1.1]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "value"],
          [:tEQUAL, "="],
          [:tFLOAT, 1.1],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches boolean' do
        source = '.send[value=true]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "value"],
          [:tEQUAL, "="],
          [:tBOOLEAN, true],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches regex' do
        source = '.send[message=/create/i]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "message"],
          [:tEQUAL, "="],
          [:tREGEXP, /create/i],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches nested value' do
        source = <<~EOS
          .send[
            receiver=
              .send[message=:create]
          ]
        EOS
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "receiver"],
          [:tEQUAL, "="],
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "message"],
          [:tEQUAL, "="],
          [:tSYMBOL, :create],
          [:tRIGHT_SQUARE, "]"],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'attribute condition' do
      it 'matches !=' do
        source = '.send[message != create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "message"],
          [:tNOT_EQUAL, "!="],
          [:tIDENTIFIER, "create"],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches >' do
        source = '[value > 1]'
        expected_tokens = [
          [:tLEFT_SQUARE, "["],
          [:tKEY, "value"],
          [:tGREATER_THAN, ">"],
          [:tINTEGER, 1],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches <' do
        source = '[value < 1]'
        expected_tokens = [
          [:tLEFT_SQUARE, "["],
          [:tKEY, "value"],
          [:tLESS_THAN, "<"],
          [:tINTEGER, 1],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches >=' do
        source = '[value >= 1]'
        expected_tokens = [
          [:tLEFT_SQUARE, "["],
          [:tKEY, "value"],
          [:tGREATER_THAN_OR_EQUAL, ">="],
          [:tINTEGER, 1],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches <=' do
        source = '[value <= 1]'
        expected_tokens = [
          [:tLEFT_SQUARE, "["],
          [:tKEY, "value"],
          [:tLESS_THAN_OR_EQUAL, "<="],
          [:tINTEGER, 1],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'nested attribute' do
      it 'matches' do
        source = '.send[receiver.message=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "receiver.message"],
          [:tEQUAL, "="],
          [:tSYMBOL, :create],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'position' do
      it 'matches :first-child' do
        source = '.send[arguments:first-child=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "arguments"],
          [:tINDEX, 0],
          [:tEQUAL, "="],
          [:tSYMBOL, :create],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches :last-child' do
        source = '.send[arguments:last-child=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "arguments"],
          [:tINDEX, -1],
          [:tEQUAL, "="],
          [:tSYMBOL, :create],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches :nth-child(1)' do
        source = '.send[arguments:nth-child(1)=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "arguments"],
          [:tINDEX, 0],
          [:tEQUAL, "="],
          [:tSYMBOL, :create],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches :nth-last-child(1)' do
        source = '.send[arguments:nth-last-child(1)=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tLEFT_SQUARE, "["],
          [:tKEY, "arguments"],
          [:tINDEX, -1],
          [:tEQUAL, "="],
          [:tSYMBOL, :create],
          [:tRIGHT_SQUARE, "]"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'descendant' do
      it 'matches' do
        source = '.class .send'
        expected_tokens = [
          [:tNODE_TYPE, "class"],
          [:tNODE_TYPE, "send"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'child' do
      it 'matches' do
        source = '.def > .send'
        expected_tokens = [
          [:tNODE_TYPE, "def"],
          [:tCHILD, ">"],
          [:tNODE_TYPE, "send"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'subsequent sibling' do
      it 'matches' do
        source = '.send ~ .send'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tSUBSEQUENT_SIBLING, "~"],
          [:tNODE_TYPE, "send"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'next sibling' do
      it 'matches' do
        source = '.send + .send'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tNEXT_SIBLING, "+"],
          [:tNODE_TYPE, "send"]
        ]
        assert_tokens source, expected_tokens
      end
    end
  end
end