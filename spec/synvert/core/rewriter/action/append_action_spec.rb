# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::AppendAction do
    describe 'class node' do
      subject do
        source = "class User\n  has_many :posts\nend"
        class_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: class_node)
        Rewriter::AppendAction.new(instance, "def as_json\n  super\nend")
      end

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "class User\n  has_many :posts".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "class User\n  has_many :posts".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\n\n  def as_json\n    super\n  end"
      end
    end

    describe 'begin node' do
      subject do
        source = "gem 'rails'\ngem 'mysql2'"
        begin_node = Parser::CurrentRuby.parse(source)
        instance = double(current_node: begin_node)
        Rewriter::AppendAction.new(instance, "gem 'twitter'")
      end

      it 'gets begin_pos' do
        expect(subject.begin_pos).to eq "gem 'rails'\ngem 'mysql2'".length
      end

      it 'gets end_pos' do
        expect(subject.end_pos).to eq "gem 'rails'\ngem 'mysql2'".length
      end

      it 'gets rewritten_code' do
        expect(subject.rewritten_code).to eq "\ngem 'twitter'"
      end
    end
  end
end
