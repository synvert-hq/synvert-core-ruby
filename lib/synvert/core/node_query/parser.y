class Synvert::Core::NodeQuery::Parser
options no_result_var
token tNODE_TYPE tATTRIBUTE tKEY tIDENTIFIER
      tCHILD tSUBSEQUENT_SIBLING tNEXT_SIBLING
      tOPEN_ATTRIBUTE tCLOSE_ATTRIBUTE tOPEN_ATTR_VALUE tCLOSE_ATTR_VALUE
      tEQUAL tNOT_EQUAL tGREATER_THAN tGREATER_THAN_OR_EQUAL tLESS_THAN tLESS_THAN_OR_EQUAL
      tATTR_VALUE tBOOLEAN tFLOAT tINTEGER tNIL tREGEXP tSTRING tSYMBOL
rule
  expression
    : selector tCHILD selector { Compiler::Expression.new(val[0], val[2], relationship: :child) }
    | selector tSUBSEQUENT_SIBLING selector { Compiler::Expression.new(val[0], val[2], relationship: :sebsequent_sibling) }
    | selector tNEXT_SIBLING selector { Compiler::Expression.new(val[0], val[2], relationship: :next_sibling) }
    | selector selector { Compiler::Expression.new(val[0], val[1], relationship: :descendant) }
    | selector { Compiler::Expression.new(val[0]) }

  selector
    : tNODE_TYPE attribute_list { Compiler::Selector.new(node_type: val[0], attribute_list: val[1]) }
    | tNODE_TYPE { Compiler::Selector.new(node_type: val[0]) }
    | attribute_list { Compiler::Selector.new(attribute_list: val[0]) }
    ;

  attribute_list
    : tOPEN_ATTRIBUTE attribute tCLOSE_ATTRIBUTE attribute_list { Compiler::AttributeList.new(val[1], val[3]) }
    | tOPEN_ATTRIBUTE attribute tCLOSE_ATTRIBUTE { Compiler::AttributeList.new(val[1]) }
    ;

  attribute
    : tKEY tNOT_EQUAL value { Compiler::Attribute.new(val[0], val[2], operation: :not_equal) }
    | tKEY tGREATER_THAN_OR_EQUAL value { Compiler::Attribute.new(val[0], val[2], operation: :greater_than_or_equal) }
    | tKEY tGREATER_THAN value { Compiler::Attribute.new(val[0], val[2], operation: :greater_than) }
    | tKEY tLESS_THAN_OR_EQUAL value { Compiler::Attribute.new(val[0], val[2], operation: :less_than_or_equal) }
    | tKEY tLESS_THAN value { Compiler::Attribute.new(val[0], val[2], operation: :less_than) }
    | tKEY tEQUAL value { Compiler::Attribute.new(val[0], val[2], operation: :equal) }

  value
    : selector
    | tOPEN_ATTR_VALUE tATTR_VALUE tCLOSE_ATTR_VALUE { Compiler::AttributeValue.new(val[1]) }
    | tBOOLEAN { Compiler::Boolean.new(val[0]) }
    | tFLOAT { Compiler::Float.new(val[0]) }
    | tINTEGER { Compiler::Integer.new(val[0])}
    | tNIL { Compiler::Nil.new(val[0]) }
    | tREGEXP { Compiler::Regexp.new(val[0]) }
    | tSTRING { Compiler::String.new(val[0]) }
    | tSYMBOL { Compiler::Symbol.new(val[0]) }
    | tIDENTIFIER { Compiler::Identifier.new(val[0]) }
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

    def on_error type, val, values
      super
    rescue Racc::ParseError
      trace = values.each_with_index.map{|l, i| "#{' ' * i}#{l}"}
      raise ParseError, "\nparse error on value #{val.inspect}\n#{trace.join("\n")}"
    end
---- header
require_relative "./compiler"