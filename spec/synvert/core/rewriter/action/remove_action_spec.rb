# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Rewriter::RemoveAction do
    subject do
      source = "user = User.new params[:user]\nuser.save\nrender\n"
      send_node = Parser::CurrentRuby.parse(source).children[1]
      instance = double(current_node: send_node)
      Rewriter::RemoveAction.new(instance)
    end

    it 'gets begin_pos' do
      expect(subject.begin_pos).to eq "user = User.new params[:user]\n".length
    end

    it 'gets end_pos' do
      expect(subject.end_pos).to eq "user = User.new params[:user]\nuser.save".length
    end

    it 'gets rewritten_code' do
      expect(subject.rewritten_code).to eq ''
    end
  end
end
