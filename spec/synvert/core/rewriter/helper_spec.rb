require 'spec_helper'

module Synvert::Core
  describe Rewriter::Helper do
    let(:dummy_instance) { Class.new { include Rewriter::Helper }.new }

    describe "add_receiver_if_necessary" do
      context "with receiver" do
        let(:node) { parse("User.save(false)") }

        it "adds reciever" do
          dummy_instance.stubs(:node).returns(node)
          expect(dummy_instance.add_receiver_if_necessary("save(validate: false)")).to eq "{{receiver}}.save(validate: false)"
        end
      end

      context "without receiver" do
        let(:node) { parse("save(false)") }

        it "doesn't add reciever" do
          dummy_instance.stubs(:node).returns(node)
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
  end
end
