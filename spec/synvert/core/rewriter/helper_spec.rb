require 'spec_helper'

module Synvert::Core
  describe Rewriter::Helper do
    let(:dummy_instance) { Class.new { include Rewriter::Helper }.new }
    let(:instance) do
      rewriter = Rewriter.new('foo', 'bar')
      Rewriter::Instance.new rewriter, 'spec/**/*_spec.rb' do; end
    end

    describe "add_receiver_if_necessary" do
      context "with receiver" do
        let(:node) { parse("User.save(false)") }

        it "adds reciever" do
          allow(dummy_instance).to receive(:node).and_return(node)
          expect(dummy_instance.add_receiver_if_necessary("save(validate: false)")).to eq "{{receiver}}.save(validate: false)"
        end
      end

      context "without receiver" do
        let(:node) { parse("save(false)") }

        it "doesn't add reciever" do
          allow(dummy_instance).to receive(:node).and_return(node)
          expect(dummy_instance.add_receiver_if_necessary("save(validate: false)")).to eq "save(validate: false)"
        end
      end
    end

    describe "strip_brackets" do
      it "strip ()" do
        expect(dummy_instance.strip_brackets("(123)")).to eq "123"
      end

      it "strip {}" do
        expect(dummy_instance.strip_brackets("{123}")).to eq "123"
      end

      it "strip []" do
        expect(dummy_instance.strip_brackets("[123]")).to eq "123"
      end

      it "not strip unmatched (]" do
        expect(dummy_instance.strip_brackets("(123]")).to eq "(123]"
      end
    end

    describe '#process_with_node' do
      it 'resets current_node' do
        node1 = double()
        node2 = double()
        instance.process_with_node(node1) do
          instance.current_node = node2
          expect(instance.current_node).to eq node2
        end
        expect(instance.current_node).to eq node1
      end
    end

    describe '#process_with_other_node' do
      it 'resets current_node' do
        node1 = double()
        node2 = double()
        node3 = double()
        instance.current_node = node1
        instance.process_with_other_node(node2) do
          instance.current_node = node3
          expect(instance.current_node).to eq node3
        end
        expect(instance.current_node).to eq node1
      end
    end
  end
end
