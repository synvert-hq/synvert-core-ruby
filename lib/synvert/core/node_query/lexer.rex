class Synvert::Core::NodeQuery::Lexer

start
  @nested_count = 0

macros
  OPEN_BRACKET   /\[/
  CLOSE_BRACKET  /]/
  NODE_TYPE      /\.[a-z]+/
  IDENTIFIER     /[\.\w]+/
  SYMBOL         /:\w+/
  INTEGER        /\d+/
  FLOAT          /\d+\.\d+/
  REGEXP_BODY    /(?:[^\/]|\\\/)*/
  REGEXP         /\/(#{REGEXP_BODY})(?<!\\)\/([imxo]*)/

rules

# [:state] pattern                   [actions]
           /\s+/
           /#{NODE_TYPE}/            { [:tNODE_TYPE, text[1..]] }
           />/                       { [:tCHILD, text] }
           /~/                       { [:tSUBSEQUENT_SIBLING, text] }
           /\+/                      { [:tNEXT_SIBLING, text] }
           /\[/                      { @nested_count += 1; @state = :KEY; [:tLEFT_SQUARE, text] }
:KEY       /\s+/
:KEY       /!=/                      { @state = :VALUE; [:tNOT_EQUAL, text] }
:KEY       />=/                      { @state = :VALUE; [:tGREATER_THAN_OR_EQUAL, text] }
:KEY       /<=/                      { @state = :VALUE; [:tLESS_THAN_OR_EQUAL, text] }
:KEY       /=/                       { @state = :VALUE; [:tEQUAL, text] }
:KEY       />/                       { @state = :VALUE; [:tGREATER_THAN, text] }
:KEY       /</                       { @state = :VALUE; [:tLESS_THAN, text] }
:KEY       /:first-child/            { [:tINDEX, 0] }
:KEY       /:last-child/             { [:tINDEX, -1] }
:KEY       /:nth-child\(\d+\)/       { [:tINDEX, text.sub(':nth-child(', '').to_i - 1] }
:KEY       /:nth-last-child\(\d+\)/  { [:tINDEX, -text.sub(':nth-last-child(', '').to_i] }
:KEY       /#{IDENTIFIER}/           { [:tKEY, text] }
:VALUE     /\s+/
:VALUE     /\]/                      { @nested_count -= 1; @state = @nested_count == 0 ? nil : :VALUE; [:tRIGHT_SQUARE, text] }
:VALUE     /nil/                     { [:tNIL, nil] }
:VALUE     /true/                    { [:tBOOLEAN, true] }
:VALUE     /false/                   { [:tBOOLEAN, false] }
:VALUE     /#{SYMBOL}/               { [:tSYMBOL, text[1..-1].to_sym] }
:VALUE     /#{FLOAT}/                { [:tFLOAT, text.to_f] }
:VALUE     /#{INTEGER}/              { [:tINTEGER, text.to_i] }
:VALUE     /#{REGEXP}/               { [:tREGEXP, eval(text)] }
:VALUE     /"(.+?)"/                 { [:tSTRING, text[1...-1]] }
:VALUE     /'(.+?)'/                 { [:tSTRING, text[1...-1]] }
:VALUE     /#{NODE_TYPE}/            { [:tNODE_TYPE, text[1..]] }
:VALUE     />/                       { [:tCHILD, text] }
:VALUE     /~/                       { [:tSUBSEQUENT_SIBLING, text] }
:VALUE     /\+/                      { [:tNEXT_SIBLING, text] }
:VALUE     /\[/                      { @state = :KEY; [:tLEFT_SQUARE, text] }
:VALUE     /#{IDENTIFIER}/           { [:tIDENTIFIER, text] }
inner
  def do_parse; end
end