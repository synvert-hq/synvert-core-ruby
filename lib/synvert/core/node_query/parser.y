class Synvert::Core::NodeQuery::Parser
options no_result_var
token tNODE_TYPE tATTRIBUTE tKEY tIDENTIFIER tIDENTIFIER_VALUE tINDEX tHAS tCOMMA
      tCHILD tSUBSEQUENT_SIBLING tNEXT_SIBLING
      tOPEN_ATTRIBUTE tCLOSE_ATTRIBUTE tOPEN_DYNAMIC_ATTRIBUTE tCLOSE_DYNAMIC_ATTRIBUTE tOPEN_ARRAY tCLOSE_ARRAY tOPEN_SELECTOR tCLOSE_SELECTOR
      tEQUAL tNOT_EQUAL tMATCH tNOT_MATCH tGREATER_THAN tGREATER_THAN_OR_EQUAL tLESS_THAN tLESS_THAN_OR_EQUAL tIN tNOT_IN tINCLUDES
      tARRAY_VALUE tDYNAMIC_ATTRIBUTE tBOOLEAN tFLOAT tINTEGER tNIL tREGEXP tSTRING tSYMBOL
rule
  expression
    : selector tCHILD expression { Compiler::Expression.new(selector: val[0], rest: val[2], relationship: :child) }
    | selector tSUBSEQUENT_SIBLING expression { Compiler::Expression.new(selector: val[0], rest: val[2], relationship: :subsequent_sibling) }
    | selector tNEXT_SIBLING expression { Compiler::Expression.new(selector: val[0], rest: val[2], relationship: :next_sibling) }
    | selector expression { Compiler::Expression.new(selector: val[0], rest: val[1], relationship: :descendant) }
    | selector { Compiler::Expression.new(selector: val[0]) }
    | tCHILD expression { Compiler::Expression.new(rest: val[1], relationship: :child) }
    | tSUBSEQUENT_SIBLING expression { Compiler::Expression.new(rest: val[1], relationship: :subsequent_sibling) }
    | tNEXT_SIBLING expression { Compiler::Expression.new(rest: val[1], relationship: :next_sibling) }

  selector
    : tNODE_TYPE attribute_list tINDEX { Compiler::Selector.new(node_type: val[0], attribute_list: val[1], index: val[2]) }
    | tNODE_TYPE tINDEX { Compiler::Selector.new(node_type: val[0], index: val[1]) }
    | attribute_list tINDEX { Compiler::Selector.new(attribute_list: val[0], index: val[1]) }
    | tNODE_TYPE attribute_list tHAS tOPEN_SELECTOR expression tCLOSE_SELECTOR { Compiler::Selector.new(node_type: val[0], attribute_list: val[1], has_expression: val[4]) }
    | tNODE_TYPE tHAS tOPEN_SELECTOR expression tCLOSE_SELECTOR { Compiler::Selector.new(node_type: val[0], has_expression: val[3]) }
    | attribute_list tHAS tOPEN_SELECTOR expression tCLOSE_SELECTOR { Compiler::Selector.new(attribute_list: val[0], has_expression: val[3]) }
    | tNODE_TYPE attribute_list { Compiler::Selector.new(node_type: val[0], attribute_list: val[1]) }
    | tNODE_TYPE { Compiler::Selector.new(node_type: val[0]) }
    | attribute_list { Compiler::Selector.new(attribute_list: val[0]) }
    ;

  attribute_list
    : tOPEN_ATTRIBUTE attribute tCLOSE_ATTRIBUTE attribute_list { Compiler::AttributeList.new(attribute: val[1], rest: val[3]) }
    | tOPEN_ATTRIBUTE attribute tCLOSE_ATTRIBUTE { Compiler::AttributeList.new(attribute: val[1]) }
    ;

  attribute
    : tKEY tNOT_EQUAL value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :!=) }
    | tKEY tNOT_MATCH value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :!~) }
    | tKEY tMATCH value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :=~) }
    | tKEY tGREATER_THAN_OR_EQUAL value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :>=) }
    | tKEY tGREATER_THAN value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :>) }
    | tKEY tLESS_THAN_OR_EQUAL value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :<=) }
    | tKEY tLESS_THAN value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :<) }
    | tKEY tEQUAL value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :==) }
    | tKEY tINCLUDES value { Compiler::Attribute.new(key: val[0], value: val[2], operator: :includes) }
    | tKEY tNOT_EQUAL tOPEN_ARRAY tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: Compiler::Array.new, operator: :!=) }
    | tKEY tEQUAL tOPEN_ARRAY tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: Compiler::Array.new, operator: :==) }
    | tKEY tNOT_IN tOPEN_ARRAY tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: Compiler::Array.new, operator: :not_in) }
    | tKEY tIN tOPEN_ARRAY tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: Compiler::Array.new, operator: :in) }
    | tKEY tNOT_EQUAL tOPEN_ARRAY array_value tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: val[3], operator: :!=) }
    | tKEY tEQUAL tOPEN_ARRAY array_value tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: val[3], operator: :==) }
    | tKEY tNOT_IN tOPEN_ARRAY array_value tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: val[3], operator: :not_in) }
    | tKEY tIN tOPEN_ARRAY array_value tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: val[3], operator: :in) }

  array_value
    : value tCOMMA array_value { Compiler::Array.new(value: val[0], rest: val[2]) }
    | value { Compiler::Array.new(value: val[0]) }

  value
    : selector
    | tOPEN_DYNAMIC_ATTRIBUTE tDYNAMIC_ATTRIBUTE tCLOSE_DYNAMIC_ATTRIBUTE { Compiler::DynamicAttribute.new(value: val[1]) }
    | tBOOLEAN { Compiler::Boolean.new(value: val[0]) }
    | tFLOAT { Compiler::Float.new(value: val[0]) }
    | tINTEGER { Compiler::Integer.new(value: val[0])}
    | tNIL { Compiler::Nil.new(value: val[0]) }
    | tREGEXP { Compiler::Regexp.new(value: val[0]) }
    | tSTRING { Compiler::String.new(value: val[0]) }
    | tSYMBOL { Compiler::Symbol.new(value: val[0]) }
    | tIDENTIFIER_VALUE { Compiler::Identifier.new(value: val[0]) }
end

---- inner
    def initialize
      @lexer = Lexer.new
    end

    def parse string
      @lexer.parse string
      do_parse
    end

    def next_token
      @lexer.next_token
    end