class Synvert::Core::NodeQuery::Lexer

macros
  OPEN_ATTRIBUTE           /\[/
  CLOSE_ATTRIBUTE          /\]/
  OPEN_ARRAY               /\(/
  CLOSE_ARRAY              /\)/
  OPEN_SELECTOR            /\(/
  CLOSE_SELECTOR           /\)/
  OPEN_DYNAMIC_ATTRIBUTE   /{{/
  CLOSE_DYNAMIC_ATTRIBUTE  /}}/
  NODE_TYPE                /\.[a-z]+/
  IDENTIFIER               /[\.\w]+/
  IDENTIFIER_VALUE         /[\.\w!&:\?<>=]+/
  FALSE                    /false/
  FLOAT                    /\d+\.\d+/
  INTEGER                  /\d+/
  NIL                      /nil/
  REGEXP_BODY              /(?:[^\/]|\\\/)*/
  REGEXP                   /\/(#{REGEXP_BODY})(?<!\\)\/([imxo]*)/
  SYMBOL                   /:[\w!\?<>=]+/
  TRUE                     /true/
  SINGLE_QUOTE_STRING      /'(.*?)'/
  DOUBLE_QUOTE_STRING      /"(.*?)"/

rules

# [:state]          pattern                       [actions]
                    /\s+/
                    /:first-child/                { [:tINDEX, 0] }
                    /:last-child/                 { [:tINDEX, -1] }
                    /:nth-child\(\d+\)/           { [:tINDEX, text.sub(':nth-child(', '').to_i - 1] }
                    /:nth-last-child\(\d+\)/      { [:tINDEX, -text.sub(':nth-last-child(', '').to_i] }
                    /:has/                        { [:tPSEUDO_CLASS, text[1..-1]] }
                    /:not_has/                    { [:tPSEUDO_CLASS, text[1..-1]] }
                    /#{NODE_TYPE}/                { [:tNODE_TYPE, text[1..]] }
                    />/                           { [:tCHILD, text] }
                    /~/                           { [:tSUBSEQUENT_SIBLING, text] }
                    /\+/                          { [:tNEXT_SIBLING, text] }
                    /#{OPEN_SELECTOR}/            { [:tOPEN_SELECTOR, text] }
                    /#{CLOSE_SELECTOR}/           { [:tCLOSE_SELECTOR, text] }
                    /#{OPEN_ATTRIBUTE}/           { @nested_count += 1; @state = :KEY; [:tOPEN_ATTRIBUTE, text] }
:KEY                /\s+/
:KEY                /!=/                          { @state = :VALUE; [:tNOT_EQUAL, text] }
:KEY                /=~/                          { @state = :VALUE; [:tMATCH, text] }
:KEY                /!~/                          { @state = :VALUE; [:tNOT_MATCH, text] }
:KEY                />=/                          { @state = :VALUE; [:tGREATER_THAN_OR_EQUAL, text] }
:KEY                /<=/                          { @state = :VALUE; [:tLESS_THAN_OR_EQUAL, text] }
:KEY                />/                           { @state = :VALUE; [:tGREATER_THAN, text] }
:KEY                /</                           { @state = :VALUE; [:tLESS_THAN, text] }
:KEY                /=/                           { @state = :VALUE; [:tEQUAL, text] }
:KEY                /includes/i                   { @state = :VALUE; [:tINCLUDES, text] }
:KEY                /not in/i                     { @state = :VALUE; [:tNOT_IN, text] }
:KEY                /in/i                         { @state = :VALUE; [:tIN, text] }
:KEY                /#{IDENTIFIER}/               { [:tKEY, text] }
:VALUE              /\s+/
:VALUE              /\[\]=/                       { [:tIDENTIFIER_VALUE, text] }
:VALUE              /\[\]/                        { [:tIDENTIFIER_VALUE, text] }
:VALUE              /:\[\]=/                      { [:tSYMBOL, text[1..-1].to_sym] }
:VALUE              /:\[\]/                       { [:tSYMBOL, text[1..-1].to_sym] }
:VALUE              /#{OPEN_DYNAMIC_ATTRIBUTE}/   { @state = :DYNAMIC_ATTRIBUTE; [:tOPEN_DYNAMIC_ATTRIBUTE, text] }
:VALUE              /#{OPEN_ARRAY}/               { @state = :ARRAY_VALUE; [:tOPEN_ARRAY, text] }
:VALUE              /#{CLOSE_ATTRIBUTE}/          { @nested_count -= 1; @state = @nested_count == 0 ? nil : :VALUE; [:tCLOSE_ATTRIBUTE, text] }
:VALUE              /#{NIL}\?/                    { [:tIDENTIFIER_VALUE, text] }
:VALUE              /#{NIL}/                      { [:tNIL, nil] }
:VALUE              /#{TRUE}/                     { [:tBOOLEAN, true] }
:VALUE              /#{FALSE}/                    { [:tBOOLEAN, false] }
:VALUE              /#{SYMBOL}/                   { [:tSYMBOL, text[1..-1].to_sym] }
:VALUE              /#{FLOAT}/                    { [:tFLOAT, text.to_f] }
:VALUE              /#{INTEGER}/                  { [:tINTEGER, text.to_i] }
:VALUE              /#{REGEXP}/                   { [:tREGEXP, eval(text)] }
:VALUE              /#{DOUBLE_QUOTE_STRING}/      { [:tSTRING, text[1...-1]] }
:VALUE              /#{SINGLE_QUOTE_STRING}/      { [:tSTRING, text[1...-1]] }
:VALUE              /#{NODE_TYPE}/                { [:tNODE_TYPE, text[1..]] }
:VALUE              /#{OPEN_ATTRIBUTE}/           { @nested_count += 1; @state = :KEY; [:tOPEN_ATTRIBUTE, text] }
:VALUE              /#{IDENTIFIER_VALUE}/         { [:tIDENTIFIER_VALUE, text] }
:DYNAMIC_ATTRIBUTE  /#{CLOSE_DYNAMIC_ATTRIBUTE}/  { @state = :VALUE; [:tCLOSE_DYNAMIC_ATTRIBUTE, text] }
:DYNAMIC_ATTRIBUTE  /#{IDENTIFIER}/               { [:tDYNAMIC_ATTRIBUTE, text] }
:ARRAY_VALUE        /\s+/
:ARRAY_VALUE        /,/                           { [:tCOMMA, text] }
:ARRAY_VALUE        /#{CLOSE_ARRAY}/              { @state = :VALUE; [:tCLOSE_ARRAY, text] }
:ARRAY_VALUE        /#{NIL}\?/                    { [:tIDENTIFIER_VALUE, text] }
:ARRAY_VALUE        /#{NIL}/                      { [:tNIL, nil] }
:ARRAY_VALUE        /#{TRUE}/                     { [:tBOOLEAN, true] }
:ARRAY_VALUE        /#{FALSE}/                    { [:tBOOLEAN, false] }
:ARRAY_VALUE        /#{SYMBOL}/                   { [:tSYMBOL, text[1..-1].to_sym] }
:ARRAY_VALUE        /#{FLOAT}/                    { [:tFLOAT, text.to_f] }
:ARRAY_VALUE        /#{INTEGER}/                  { [:tINTEGER, text.to_i] }
:ARRAY_VALUE        /#{REGEXP}/                   { [:tREGEXP, eval(text)] }
:ARRAY_VALUE        /#{DOUBLE_QUOTE_STRING}/      { [:tSTRING, text[1...-1]] }
:ARRAY_VALUE        /#{SINGLE_QUOTE_STRING}/      { [:tSTRING, text[1...-1]] }
:ARRAY_VALUE        /#{IDENTIFIER_VALUE}/         { [:tIDENTIFIER_VALUE, text] }

inner
  def initialize
    @nested_count = 0
  end

  def do_parse; end
end