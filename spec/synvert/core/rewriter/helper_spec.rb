# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::Helper do
    let(:dummy_instance) { Class.new { include Rewriter::Helper }.new }
    let(:instance) do
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new rewriter, 'spec/**/*_spec.rb' do
      end
    end

    describe 'add_receiver_if_necessary' do
      context 'with receiver' do
        let(:node) { parse('User.save(false)') }

        it 'adds reciever' do
          allow(dummy_instance).to receive(:node).and_return(node)
          expect(
            dummy_instance.add_receiver_if_necessary('save(validate: false)')
          ).to eq '{{receiver}}.save(validate: false)'
        end
      end

      context 'without receiver' do
        let(:node) { parse('save(false)') }

        it "doesn't add reciever" do
          allow(dummy_instance).to receive(:node).and_return(node)
          expect(dummy_instance.add_receiver_if_necessary('save(validate: false)')).to eq 'save(validate: false)'
        end
      end
    end

    describe 'add_arguments_with_parenthesis_if_necessary' do
      context 'with arguments' do
        let(:node) { parse('user.save(false)') }

        it 'gets arguments with parenthesis' do
          allow(dummy_instance).to receive(:node).and_return(node)
          expect(dummy_instance.add_arguments_with_parenthesis_if_necessary).to eq '({{arguments}})'
        end
      end

      context 'without argument' do
        let(:node) { parse('user.save') }

        it 'gets nothing' do
          allow(dummy_instance).to receive(:node).and_return(node)
          expect(dummy_instance.add_arguments_with_parenthesis_if_necessary).to eq ''
        end
      end
    end

    describe 'add_curly_brackets_if_necessary' do
      it 'add {} if code does not have' do
        expect(dummy_instance.add_curly_brackets_if_necessary('foo: bar')).to eq '{ foo: bar }'
      end

      it "doesn't add {} if code already has" do
        expect(dummy_instance.add_curly_brackets_if_necessary('{foo: bar}')).to eq '{foo: bar}'
      end
    end

    describe 'strip_brackets' do
      it 'strip ()' do
        expect(dummy_instance.strip_brackets('(123)')).to eq '123'
      end

      it 'strip {}' do
        expect(dummy_instance.strip_brackets('{123}')).to eq '123'
      end

      it 'strip []' do
        expect(dummy_instance.strip_brackets('[123]')).to eq '123'
      end

      it 'not strip unmatched (]' do
        expect(dummy_instance.strip_brackets('(123]')).to eq '(123]'
      end
    end

    describe '#reject_keys_from_hash' do
      it 'rejects single key' do
        hash_node = Parser::CurrentRuby.parse("{ key1: 'value1', key2: 'value2' }")
        expect(dummy_instance.reject_keys_from_hash(hash_node, :key1)).to eq "key2: 'value2'"
      end

      it 'rejects multi keys' do
        hash_node = Parser::CurrentRuby.parse("{ key1: 'value1', key2: 'value2', key3: 'value3', key4: 'value4' }")
        expect(dummy_instance.reject_keys_from_hash(hash_node, :key1, :key3)).to eq "key2: 'value2', key4: 'value4'"
      end
    end
  end
end
