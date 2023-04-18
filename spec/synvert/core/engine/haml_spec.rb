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
              #error= error_message
              .form-actions
                = form_for @user do |f|
            - elsif current_user?
              %span= "User"
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

      it 'encodes plain text' do
        source = <<~EOS
          %gee
            %whiz
              Wow this is cool!
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).not_to be_include '%gee'
        expect(encoded_source).not_to be_include '%whiz'
        expect(encoded_source).not_to be_include 'Wow this is cool!'
      end

      it 'encodes escaping' do
        source = <<~EOS
          %title
            = @title
            \\= @title
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source.scan('@title').length).to eq 1
      end

      it 'encodes attributes' do
        source = <<~EOS
          %html{:xmlns => "http://www.w3.org/1999/xhtml", "xml:lang" => "en", :lang => "en"}
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include '{:xmlns => "http://www.w3.org/1999/xhtml", "xml:lang" => "en", :lang => "en"}'
      end

      it 'encodes multiple lines attributes' do
        source = <<~EOS
          %script{
            "type": "text/javascript",
            "src": "javascripts/script_9",
            "data": {
              "controller": "reporter",
            },
          }
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include '"type": "text/javascript",'
        expect(encoded_source).to be_include '"src": "javascripts/script_9",'
        expect(encoded_source).to be_include '"controller": "reporter",'
      end

      it 'encodes prefixed attributes' do
        source = <<~EOS
          %a{:href=>"/posts", :data => {:author_id => 123, :category => 7}} Posts By Author
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include '{:href=>"/posts", :data => {:author_id => 123, :category => 7}}'
      end

      it 'encodes class and ID' do
        source = <<~EOS
          %div#things
            %span#rice Chicken Fried
            %p.beans{ :food => 'true' } The magical fruit
            %h1.class.otherclass#id La La La
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).not_to be_include '%div'
        expect(encoded_source).not_to be_include '#things'
        expect(encoded_source).not_to be_include '.beans'
        expect(encoded_source).not_to be_include '.class'
        expect(encoded_source).not_to be_include '#id'
        expect(encoded_source).to be_include "{ :food => 'true' }"
      end

      it 'encodes haml comments' do
        source = <<~EOS
          %p foo
          -# This is a comment
          %p bar
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).not_to be_include 'foo'
        expect(encoded_source).not_to be_include 'bar'
        expect(encoded_source).to be_include '# This is a comment'
      end

      it 'encodes ruby evaluation' do
        source = <<~EOS
          %p
            = ['hi', 'there', 'reader!'].join " "
            = "yo"
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include "['hi', 'there', 'reader!'].join \" \""
        expect(encoded_source).to be_include '"yo"'
      end

      it 'encodes ruby evaluation in the same line' do
        source = <<~EOS
          %p= "hello"
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).not_to be_include '%p'
        expect(encoded_source).to be_include '"hello"'
      end

      it 'encodes multiple lines ruby evaluation' do
        source = <<~EOS
          = link_to_remote "Add to cart",
            :url => { :action => "add", :id => product.id },
            :update => { :success => "cart", :failure => "error" }
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include 'link_to_remote "Add to cart",'
        expect(encoded_source).to be_include ':url => { :action => "add", :id => product.id },'
        expect(encoded_source).to be_include ':update => { :success => "cart", :failure => "error" }'
      end

      it 'encodes running ruby' do
        source = <<~EOS
          - foo = "hello"
          - foo << " there"
          - foo << " you!"
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include 'foo = "hello"'
        expect(encoded_source).to be_include 'foo << " there"'
        expect(encoded_source).to be_include 'foo << " you!"'
      end

      it 'encodes multiple line running ruby' do
        source = <<~EOS
          - links = {:home => "/",
              :docs => "/docs",
              :about => "/about"}
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include 'links = {:home => "/",'
        expect(encoded_source).to be_include ':docs => "/docs",'
        expect(encoded_source).to be_include ':about => "/about"}'
      end

      it 'encodes ruby block' do
        source = <<~EOS
          - (42...47).each do |i|
            %p= i
          %p See, I can count!
        EOS
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include '(42...47).each do |i|'
        expect(encoded_source).to be_include 'end'
        expect(encoded_source).not_to be_include 'See, I can count!'
      end

      it 'encodes ruby interpolation' do
        source = 'Look at #{h word} lack of backslash: \#{foo}'
        encoded_source = Engine::Haml.encode(source)
        expect(encoded_source).to be_include 'h word;'
        expect(encoded_source).not_to be_include 'foo'
        expect(encoded_source).not_to be_include 'lack of backslash:'
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
          NodeMutation::Struct::Action.new(:delete, 50, 55, ''),
          # first end position is 69
          NodeMutation::Struct::Action.new(:delete, 100, 105, ''),
          # second end position is 111
          NodeMutation::Struct::Action.new(:delete, 120, 125, '')
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
