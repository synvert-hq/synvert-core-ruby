# frozen_string_literal: true

require 'spec_helper'

module Synvert::Core
  describe Engine::Erb do
    it 'encodes / decodes' do
      source = <<~EOF
        <% content_for :head do %>
          <style>
            body {
              background-image: url(<%= asset_path('bg.png') %>);
            }
          </style>
        <% end %>

        <%
          foo = 'bar'
          post = Post.find(:first)
          bar = 'foo'
        %>

        <% if User.current &&
              User.current.admin %>
          <%= rounded_content("page") do %>
          <div class='test'>
            <% if post %>
              <div id="title"><%= foo %></div>
              <% form_for post do |f| %>
                <label><%= link_to_function 'test', "confirm('test');" %></label>
                <%= f.text_field 'bar' %>
              <% end %>
            <% end %></div>
          <% end %>
        <% end %>
      EOF
      encoded_source = Engine::Erb.encode(source)
      expect(encoded_source).to be_include 'content_for :head do'
      expect(encoded_source).to be_include " asset_path('bg.png')"
      expect(encoded_source).to be_include 'post = Post.find(:first)'
      expect(encoded_source).to be_include "link_to_function 'test', \"confirm('test');\""
      expect(encoded_source).to be_include 'end'
      expect(encoded_source).not_to be_include 'style'
      expect(encoded_source).not_to be_include 'div'
    end
  end
end
