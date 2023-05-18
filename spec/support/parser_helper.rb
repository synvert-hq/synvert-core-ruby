# frozen_string_literal: true

module ParserHelper
  def parser_parse(code)
    Parser::CurrentRuby.parse code
  end
end
