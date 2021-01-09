require 'spec_helper'

module Synvert::Core
  describe Engine::ERB do
    it "encodes / decodes" do
      source =<<~EOF
        <%content_for :head do%>
          <style>
            body {
              background-image: url(<%= asset_path('bg.png') %>);
            }
          </style>
        <%end%>
        
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
      encoded_source = Engine::ERB.encode(source)
      buffer = Parser::Source::Buffer.new "(test)"
      buffer.source = encoded_source
      parser = Parser::CurrentRuby.new
      parser.reset
      parser.parse buffer

      expect(Engine::ERB.decode(encoded_source)).to eq source
    end
  end
end
