class Synvert::Core::NodeQuery::Lexer

macros
  OPEN_ATTRIBUTE    /\[/
  CLOSE_ATTRIBUTE   /\]/
  OPEN_ATTR_VALUE   /\{\{/
  CLOSE_ATTR_VALUE  /\}\}/
  NODE_TYPE         /\.[a-z]+/
  IDENTIFIER        /[\.\w]+/
  IDENTIFIER_VALUE  /[\.\w!]+/
  SYMBOL            /:\w+/
  INTEGER           /\d+/
  FLOAT             /\d+\.\d+/
  REGEXP_BODY       /(?:[^\/]|\\\/)*/
  REGEXP            /\/(#{REGEXP_BODY})(?<!\\)\/([imxo]*)/

rules

# [:state]   pattern                   [actions]
             /\s+/
             /:first-child/            { [:tINDEX, 0] }
             /:last-child/             { [:tINDEX, -1] }
             /:nth-child\(\d+\)/       { [:tINDEX, text.sub(':nth-child(', '').to_i - 1] }
             /:nth-last-child\(\d+\)/  { [:tINDEX, -text.sub(':nth-last-child(', '').to_i] }
             /#{NODE_TYPE}/            { [:tNODE_TYPE, text[1..]] }
             />/                       { [:tCHILD, text] }
             /~/                       { [:tSUBSEQUENT_SIBLING, text] }
             /\+/                      { [:tNEXT_SIBLING, text] }
             /#{OPEN_ATTRIBUTE}/       { @nested_count += 1; @state = :KEY; [:tOPEN_ATTRIBUTE, text] }
:KEY         /\s+/
:KEY         /!=/                      { @state = :VALUE; [:tNOT_EQUAL, text] }
:KEY         /=~/                      { @state = :VALUE; [:tMATCH, text] }
:KEY         /!~/                      { @state = :VALUE; [:tNOT_MATCH, text] }
:KEY         />=/                      { @state = :VALUE; [:tGREATER_THAN_OR_EQUAL, text] }
:KEY         /<=/                      { @state = :VALUE; [:tLESS_THAN_OR_EQUAL, text] }
:KEY         />/                       { @state = :VALUE; [:tGREATER_THAN, text] }
:KEY         /</                       { @state = :VALUE; [:tLESS_THAN, text] }
:KEY         /=/                       { @state = :VALUE; [:tEQUAL, text] }
:KEY         /#{IDENTIFIER}/           { [:tKEY, text] }
:VALUE       /\s+/
:VALUE       /#{OPEN_ATTR_VALUE}/      { @state = :ATTR_VALUE; [:tOPEN_ATTR_VALUE, text] }
:VALUE       /#{CLOSE_ATTRIBUTE}/      { @nested_count -= 1; @state = @nested_count == 0 ? nil : :VALUE; [:tCLOSE_ATTRIBUTE, text] }
:VALUE       /nil/                     { [:tNIL, nil] }
:VALUE       /true/                    { [:tBOOLEAN, true] }
:VALUE       /false/                   { [:tBOOLEAN, false] }
:VALUE       /#{SYMBOL}/               { [:tSYMBOL, text[1..-1].to_sym] }
:VALUE       /#{FLOAT}/                { [:tFLOAT, text.to_f] }
:VALUE       /#{INTEGER}/              { [:tINTEGER, text.to_i] }
:VALUE       /#{REGEXP}/               { [:tREGEXP, eval(text)] }
:VALUE       /"(.+?)"/                 { [:tSTRING, text[1...-1]] }
:VALUE       /'(.+?)'/                 { [:tSTRING, text[1...-1]] }
:VALUE       /#{NODE_TYPE}/            { [:tNODE_TYPE, text[1..]] }
:VALUE       />/                       { [:tCHILD, text] }
:VALUE       /~/                       { [:tSUBSEQUENT_SIBLING, text] }
:VALUE       /\+/                      { [:tNEXT_SIBLING, text] }
:VALUE       /#{OPEN_ATTRIBUTE}/       { @nested_count += 1; @state = :KEY; [:tOPEN_ATTRIBUTE, text] }
:VALUE       /#{IDENTIFIER_VALUE}/     { [:tIDENTIFIER_VALUE, text] }
:ATTR_VALUE  /#{CLOSE_ATTR_VALUE}/     { @state = :VALUE; [:tCLOSE_ATTR_VALUE, text] }
:ATTR_VALUE  /#{IDENTIFIER}/           { [:tATTR_VALUE, text] }

inner
  def initialize
    @nested_count = 0
  end

  def do_parse; end
end