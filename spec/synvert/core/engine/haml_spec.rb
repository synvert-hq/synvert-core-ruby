# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Engine::Haml do
    describe '#encode' do
      it 'encodes source' do
        source = <<~EOS
          %p
            Date/Time:
            - now = DateTime.now
            %strong= now
            - if now > DateTime.parse("December 31, 2006")
              = "Happy new " + "year!"
            - else
              = "Hello!"
            - if current_admin?
              %strong= "Admin"
            - elsif current_user?
              %span= "User"
          #error= error_message
          .form-actions
            = form_for @user do |f|
          Test
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include 'now = DateTime.now'
        expect(encoded_source).to be_include 'now'
        expect(encoded_source).to be_include 'if now > DateTime.parse("December 31, 2006")'
        expect(encoded_source).to be_include '"Happy new " + "year!"'
        expect(encoded_source).to be_include '"Hello!"'
        expect(encoded_source).to be_include 'if current_admin?'
        expect(encoded_source).to be_include '"Admin"'
        expect(encoded_source).to be_include 'if current_user?'
        expect(encoded_source).to be_include '"User"'
        expect(encoded_source).to be_include 'error_message'
        expect(encoded_source).to be_include 'form_for @user do |f|'
        expect(encoded_source.scan("end\n").length).to eq 3
        expect(encoded_source).not_to be_include '%p'
        expect(encoded_source).not_to be_include 'strong'
        expect(encoded_source).not_to be_include '#error'
        expect(encoded_source).not_to be_include 'Test'
        expect(encoded_source).not_to be_include '.form-actions'
      end
    end

    describe '#generate_transform_proc' do
      it 'generates transform proc' do
        encoded_source = <<~EOS
          now = DateTime.now
          if now > DateTime.parse("December 31, 2006")
          else
          end
          if current_admin?
          elsif current_user?
          end
          DateTime.now - now
        EOS
        proc = Engine::Haml.generate_transform_proc(encoded_source)
        actions = [
          NodeMutation::Struct::Action.new(50, 55, ''),
          # first end position is 69
          NodeMutation::Struct::Action.new(100, 105, ''),
          # second end position is 111
          NodeMutation::Struct::Action.new(120, 125, '')
        ]
        proc.call(actions)
        expect(actions.first.start).to eq 50
        expect(actions.first.end).to eq 55
        expect(actions.second.start).to eq 96
        expect(actions.second.end).to eq 101
        expect(actions.third.start).to eq 112
        expect(actions.third.end).to eq 117
      end
    end
  end
end
