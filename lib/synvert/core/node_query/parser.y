class Synvert::Core::NodeQuery::Parser
options no_result_var
token tNODE_TYPE tGOTO_SCOPE tATTRIBUTE tKEY tIDENTIFIER tIDENTIFIER_VALUE tPSEUDO_CLASS tRELATIONSHIP
      tOPEN_ATTRIBUTE tCLOSE_ATTRIBUTE tOPEN_DYNAMIC_ATTRIBUTE tCLOSE_DYNAMIC_ATTRIBUTE
      tOPEN_ARRAY tCLOSE_ARRAY tOPEN_SELECTOR tCLOSE_SELECTOR
      tOPERATOR tARRAY_VALUE tDYNAMIC_ATTRIBUTE tBOOLEAN tFLOAT tINTEGER tNIL tREGEXP tSTRING tSYMBOL
rule
  expression
    : selector expression { Compiler::Expression.new(selector: val[0], rest: val[1]) }
    | selector { Compiler::Expression.new(selector: val[0]) }

  selector
    : basic_selector { Compiler::Selector.new(basic_selector: val[0]) }
    | tPSEUDO_CLASS tOPEN_SELECTOR selector tCLOSE_SELECTOR { Compiler::Selector.new(pseudo_class: val[0], pseudo_selector: val[2]) }
    | tRELATIONSHIP selector { Compiler::Selector.new(relationship: val[0], rest: val[1]) }
    | tGOTO_SCOPE selector { Compiler::Selector.new(goto_scope: val[0], rest: val[1]) }

  basic_selector
    : tNODE_TYPE { Compiler::BasicSelector.new(node_type: val[0]) }
    | tNODE_TYPE attribute_list { Compiler::BasicSelector.new(node_type: val[0], attribute_list: val[1]) }

  attribute_list
    : tOPEN_ATTRIBUTE attribute tCLOSE_ATTRIBUTE attribute_list { Compiler::AttributeList.new(attribute: val[1], rest: val[3]) }
    | tOPEN_ATTRIBUTE attribute tCLOSE_ATTRIBUTE { Compiler::AttributeList.new(attribute: val[1]) }

  attribute
    : tKEY tOPERATOR value { Compiler::Attribute.new(key: val[0], value: val[2], operator: val[1]) }
    | tKEY tOPERATOR tOPEN_ARRAY tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: Compiler::Array.new, operator: val[1]) }
    | tKEY tOPERATOR tOPEN_ARRAY array_value tCLOSE_ARRAY { Compiler::Attribute.new(key: val[0], value: val[3], operator: val[1]) }

  array_value
    : value array_value { Compiler::Array.new(value: val[0], rest: val[1]) }
    | value { Compiler::Array.new(value: val[0]) }

  value
    : basic_selector
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