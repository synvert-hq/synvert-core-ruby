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
        expected_tokens = [[:tNODE_TYPE, "send"]]
        assert_tokens source, expected_tokens
      end
    end

    context 'attribute value' do
      it 'matches =' do
        source = '.send[message=create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, "create"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches nil' do
        source = '.send[receiver=nil]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "receiver"],
          [:tOPERATOR, "=="],
          [:tNIL, nil],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches string' do
        source = '.send[message="create"]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tSTRING, "create"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches "[]"' do
        source = '.send[message="[]"]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tSTRING, "[]"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches symbol' do
        source = '.send[message=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tSYMBOL, :create],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches integer' do
        source = '[value=1]'
        expected_tokens = [
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "value"],
          [:tOPERATOR, "=="],
          [:tINTEGER, 1],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches float' do
        source = '.send[value=1.1]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "value"],
          [:tOPERATOR, "=="],
          [:tFLOAT, 1.1],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches boolean' do
        source = '.send[value=true]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "value"],
          [:tOPERATOR, "=="],
          [:tBOOLEAN, true],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'identifier can contain !' do
        source = '.send[message=create!]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, "create!"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'identifier can contain ?' do
        source = '.send[message=empty?]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, "empty?"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'identifier can contain <, >, =' do
        source = '.send[message=<]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, "<"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens

        source = '.send[message==]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, "="],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens

        source = '.send[message=>]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, ">"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches empty string' do
        source = ".send[arguments.first='']"
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "arguments.first"],
          [:tOPERATOR, "=="],
          [:tSTRING, ""],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches :[] message' do
        source = ".send[message=[]]"
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, "[]"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches :[] message' do
        source = ".send[message=:[]=]"
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tSYMBOL, :[]=],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches nil?' do
        source = ".send[message=nil?]"
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tIDENTIFIER_VALUE, "nil?"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches attribute value' do
        source = '.pair[key={{value}}]'
        expected_tokens = [
          [:tNODE_TYPE, "pair"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "key"],
          [:tOPERATOR, "=="],
          [:tDYNAMIC_ATTRIBUTE, "value"],
          [:tCLOSE_ATTRIBUTE, "]"]
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
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "receiver"],
          [:tOPERATOR, "=="],
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=="],
          [:tSYMBOL, :create],
          [:tCLOSE_ATTRIBUTE, "]"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches deep nested value' do
        source = <<~EOS
          .send[
            arguments=[size=2][first=.str][last=.str]
          ]
        EOS
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "arguments"],
          [:tOPERATOR, "=="],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "size"],
          [:tOPERATOR, "=="],
          [:tINTEGER, 2],
          [:tCLOSE_ATTRIBUTE, "]"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "first"],
          [:tOPERATOR, "=="],
          [:tNODE_TYPE, "str"],
          [:tCLOSE_ATTRIBUTE, "]"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "last"],
          [:tOPERATOR, "=="],
          [:tNODE_TYPE, "str"],
          [:tCLOSE_ATTRIBUTE, "]"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'attribute condition' do
      it 'matches !=' do
        source = '.send[message != create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "!="],
          [:tIDENTIFIER_VALUE, "create"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches >' do
        source = '[value > 1]'
        expected_tokens = [
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "value"],
          [:tOPERATOR, ">"],
          [:tINTEGER, 1],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches <' do
        source = '[value < 1]'
        expected_tokens = [
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "value"],
          [:tOPERATOR, "<"],
          [:tINTEGER, 1],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches >=' do
        source = '[value >= 1]'
        expected_tokens = [
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "value"],
          [:tOPERATOR, ">="],
          [:tINTEGER, 1],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches <=' do
        source = '[value <= 1]'
        expected_tokens = [
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "value"],
          [:tOPERATOR, "<="],
          [:tINTEGER, 1],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches =~' do
        source = '.send[message=~/create/i]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "=~"],
          [:tREGEXP, /create/i],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches !~' do
        source = '.send[message!~/create/i]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "!~"],
          [:tREGEXP, /create/i],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matche empty array' do
        source = '.send[arguments=()]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "arguments"],
          [:tOPERATOR, "=="],
          [:tOPEN_ARRAY, "("],
          [:tCLOSE_ARRAY, ")"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matche equal array' do
        source = '.send[arguments=(:create)]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "arguments"],
          [:tOPERATOR, "=="],
          [:tOPEN_ARRAY, "("],
          [:tSYMBOL, :create],
          [:tCLOSE_ARRAY, ")"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matche not equal array' do
        source = '.send[arguments!=(:create)]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "arguments"],
          [:tOPERATOR, "!="],
          [:tOPEN_ARRAY, "("],
          [:tSYMBOL, :create],
          [:tCLOSE_ARRAY, ")"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches IN' do
        source = '.send[message IN (create build)]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "in"],
          [:tOPEN_ARRAY, "("],
          [:tIDENTIFIER_VALUE, "create"],
          [:tIDENTIFIER_VALUE, "build"],
          [:tCLOSE_ARRAY, ")"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches NOT IN' do
        source = '.send[message NOT IN (create build)]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "message"],
          [:tOPERATOR, "not_in"],
          [:tOPEN_ARRAY, "("],
          [:tIDENTIFIER_VALUE, "create"],
          [:tIDENTIFIER_VALUE, "build"],
          [:tCLOSE_ARRAY, ")"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end

      it 'matches INCLUDES' do
        source = '.send[arguments INCLUDES &block]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "arguments"],
          [:tOPERATOR, "includes"],
          [:tIDENTIFIER_VALUE, "&block"],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'nested attribute' do
      it 'matches' do
        source = '.send[receiver.message=:create]'
        expected_tokens = [
          [:tNODE_TYPE, "send"],
          [:tOPEN_ATTRIBUTE, "["],
          [:tKEY, "receiver.message"],
          [:tOPERATOR, "=="],
          [:tSYMBOL, :create],
          [:tCLOSE_ATTRIBUTE, "]"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'descendant' do
      it 'matches' do
        source = '.class .send'
        expected_tokens = [[:tNODE_TYPE, "class"], [:tNODE_TYPE, "send"]]
        assert_tokens source, expected_tokens
      end
    end

    context 'child' do
      it 'matches' do
        source = '.def > .send'
        expected_tokens = [[:tNODE_TYPE, "def"], [:tRELATIONSHIP, ">"], [:tNODE_TYPE, "send"]]
        assert_tokens source, expected_tokens
      end
    end

    context 'subsequent sibling' do
      it 'matches' do
        source = '.send ~ .send'
        expected_tokens = [[:tNODE_TYPE, "send"], [:tRELATIONSHIP, "~"], [:tNODE_TYPE, "send"]]
        assert_tokens source, expected_tokens
      end
    end

    context 'next sibling' do
      it 'matches' do
        source = '.send + .send'
        expected_tokens = [[:tNODE_TYPE, "send"], [:tRELATIONSHIP, "+"], [:tNODE_TYPE, "send"]]
        assert_tokens source, expected_tokens
      end
    end

    context ':has' do
      it 'matches' do
        source = '.class:has(> .def)'
        expected_tokens = [
          [:tNODE_TYPE, "class"],
          [:tPSEUDO_CLASS, "has"],
          [:tOPEN_SELECTOR, "("],
          [:tRELATIONSHIP, ">"],
          [:tNODE_TYPE, "def"],
          [:tCLOSE_SELECTOR, ")"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context ':not_has' do
      it 'matches' do
        source = '.class:not_has(> .def)'
        expected_tokens = [
          [:tNODE_TYPE, "class"],
          [:tPSEUDO_CLASS, "not_has"],
          [:tOPEN_SELECTOR, "("],
          [:tRELATIONSHIP, ">"],
          [:tNODE_TYPE, "def"],
          [:tCLOSE_SELECTOR, ")"]
        ]
        assert_tokens source, expected_tokens
      end
    end

    context 'goto_scope' do
      it 'matches' do
        source = '.block body > .def'
        expected_tokens = [
          [:tNODE_TYPE, "block"],
          [:tGOTO_SCOPE, "body"],
          [:tRELATIONSHIP, ">"],
          [:tNODE_TYPE, "def"]
        ]
        assert_tokens source, expected_tokens
      end
    end
  end
end
