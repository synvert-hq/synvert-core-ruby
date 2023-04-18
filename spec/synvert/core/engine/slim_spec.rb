# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Engine::Slim do
    describe '#encode' do
      it 'encodes source' do
        source = <<~EOS
          doctype html
          html
            head
              title Slim Examples
              meta name="keywords" content="template language"
              meta name="author" content=author
              javascript:
                alert('Slim supports embedded javascript!')

            body
              h1 Markup examples

              #content
                p This example shows you what a basic Slim file looks like.

                == yield

                - unless items.empty?
                  table
                    - items.each do |item|
                      tr
                        td.name = item.name
                        td.price = item.price
                - else
                  p
                  | No items found.  Please add some inventory.
                    Thank you!

              div id="footer"
                = render 'footer'
                | Copyright © \#{year} \#{author}
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'yield'
        expect(encoded_source).to be_include 'unless items.empty?'
        expect(encoded_source).to be_include 'items.each do |item|'
        expect(encoded_source).to be_include 'item.name'
        expect(encoded_source).to be_include 'item.price'
        expect(encoded_source).to be_include "render 'footer'"
        expect(encoded_source).to be_include 'year'
        expect(encoded_source).to be_include 'author'
        expect(encoded_source.scan("end\n").length).to eq 2
        expect(encoded_source).not_to be_include 'html'
        expect(encoded_source).not_to be_include 'meta'
        expect(encoded_source).not_to be_include 'javascript:'
        expect(encoded_source).not_to be_include 'Markup examples'
        expect(encoded_source).not_to be_include 'td.name'
        expect(encoded_source).not_to be_include 'td.price'
        expect(encoded_source).not_to be_include 'Copyright'
      end

      it 'encodes control code' do
        source = <<~EOS
          body
            - if articles.empty?
              | No inventory
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'if articles.empty?'
        expect(encoded_source).to be_include 'end'
        expect(encoded_source).not_to be_include 'No inventory'
      end

      it 'encodes output' do
        source = <<~EOS
          = javascript_include_tag \
              "jquery",
              "application"
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'javascript_include_tag'
        expect(encoded_source).to be_include '"jquery",'
        expect(encoded_source).to be_include '"application"'
      end

      it 'encodes output without html escaping' do
        source = <<~EOS
          == yield
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'yield'
      end

      it 'encodes tags' do
        source = <<~EOS
          ul
            li.first: a href="/a" A link
            li: a href="/b" B link
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).not_to be_include 'ul'
        expect(encoded_source).not_to be_include 'li'
        expect(encoded_source).not_to be_include 'first'
        expect(encoded_source).not_to be_include 'link'
      end

      it 'encodes text content' do
        source = <<~EOS
          body
            h1 id="headline" Welcome to my site.
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).not_to be_include 'h1'
        expect(encoded_source).not_to be_include 'id'
        expect(encoded_source).not_to be_include 'Welcome'
      end

      it 'encodes dynamic content' do
        source = <<~EOS
          body
            h1 id="headline" = page_headline
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'page_headline'
        expect(encoded_source).not_to be_include 'h1'
      end

      it 'encodes attributes wrapper' do
        source = <<~EOS
          body
            h1(id="logo") = page_logo
            h2[id="tagline" class="small tagline"] = page_tagline
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'page_logo'
        expect(encoded_source).to be_include 'page_tagline'
        expect(encoded_source).not_to be_include 'h1'
        expect(encoded_source).not_to be_include 'h2'
        expect(encoded_source).not_to be_include 'id'
        expect(encoded_source).not_to be_include 'class'
      end

      it 'encodes multiple lines attributes wrapper' do
        source = <<~EOS
          h2[id="tagline"
              class="small tagline"] = page_tagline
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'page_tagline'
        expect(encoded_source).not_to be_include 'h2'
        expect(encoded_source).not_to be_include 'id'
        expect(encoded_source).not_to be_include 'class'
      end

      it 'encodes ruby attributes' do
        source = <<~EOS
          body
            table
              - for user in users
                td id="user_\#{user.id}" class=user.role
                  a href=user_action(user, :edit) Edit \#{user.first_name}
                  a href=(path_to_user user) = user.last_name
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'for user in users'
        expect(encoded_source).to be_include 'user.id'
        expect(encoded_source).to be_include 'user_action(user, :edit)'
        expect(encoded_source).to be_include 'user.first_name'
        expect(encoded_source).to be_include '(path_to_user user)'
        expect(encoded_source).to be_include 'user.last_name'
        expect(encoded_source).to be_include 'end'
        expect(encoded_source).not_to be_include 'href'
      end

      it 'encodes ruby attributes with ==' do
        source = 'a href==action_path(:start)'
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'action_path(:start)'
        expect(encoded_source).not_to be_include 'href'
        expect(encoded_source).not_to be_include '='
      end

      it 'encodes text interpolation' do
        source = <<~EOS
          body
            h1 Welcome \#{current_user.name} to the show.
        EOS
        encoded_source = Engine::Slim.encode(source)
        expect(encoded_source).to be_include 'current_user.name;'
        expect(encoded_source).not_to be_include 'Welcome'
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
        proc = Engine::Slim.generate_transform_proc(encoded_source)
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
