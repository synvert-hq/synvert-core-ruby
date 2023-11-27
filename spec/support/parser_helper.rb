# frozen_string_literal: true

require 'parser/current'
require 'parser_node_ext'

module ParserHelper
  def parser_parse(code)
    Parser::CurrentRuby.parse code
  end
end
