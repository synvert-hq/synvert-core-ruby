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
