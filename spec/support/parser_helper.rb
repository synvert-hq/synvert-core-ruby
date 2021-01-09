# frozen_string_literal: true

module ParserHelper
  def parse(code)
    Parser::CurrentRuby.parse code
  end
end
