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
      encoded_lines = Engine::Erb.encode(source).split("\n")
      expect(encoded_lines[0]).to eq '   content_for :head do   '
      expect(encoded_lines[1]).to eq "                                                     asset_path('bg.png')     "
      expect(encoded_lines[-2]).to eq '     end   '
      expect(encoded_lines[-1]).to eq '   end   '
    end
  end
end
