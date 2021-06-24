# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::ReplaceWithAction do
    context 'replace with single line' do
      subject {
        source = 'post = FactoryGirl.create_list :post, 2'
        send_node = Parser::CurrentRuby.parse(source).children[1]
        instance = double(current_node: send_node)
        Rewriter::ReplaceWithAction.new(instance, 'create_list {{arguments}}')
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 'post = '.length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq 'post = FactoryGirl.create_list :post, 2'.length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq 'create_list :post, 2'
      end
    end

    context '#replace with multiple line' do
      subject {
        source = '  its(:size) { should == 1 }'
        send_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: send_node)
        Rewriter::ReplaceWithAction.new(instance, <<~EOS)
          describe '#size' do
            subject { super().size }
            it { {{body}} }
          end
          EOS
      }

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq 2
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq '  its(:size) { should == 1 }'.length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq <<~EOS.strip
          describe '#size' do
              subject { super().size }
              it { should == 1 }
            end
        EOS
      end
    end
  end
end
