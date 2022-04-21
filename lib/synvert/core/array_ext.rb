# frozen_string_literal: true

# Extend Array.
class Array
  # Get child node by the name.
  #
  # @param child_name [String] name of child node.
  # @return [Parser::AST::Node] the child node.
  def child_node_by_name(child_name)
    direct_child_name, nested_child_name = child_name.split('.', 2)
    child_direct_child_node = direct_child_name =~ /\A\d+\z/ ? self[direct_child_name.to_i - 1] : self.send(direct_child_name)
    return child_direct_child_node.child_node_by_name(nested_child_name) if nested_child_name
    return child_direct_child_node if child_direct_child_node

    raise Synvert::Core::MethodNotSupported,
          "child_node_by_name is not handled for #{debug_info}, child_name: #{child_name}"
  end

  # Get the source range of child node.
  #
  # @param child_name [String] name of child node.
  # @return [Parser::Source::Range] source range of child node.
  def child_node_range(child_name)
    direct_child_name, nested_child_name = child_name.split('.', 2)
    child_direct_child_node = direct_child_name =~ /\A\d+\z/ ? self[direct_child_name.to_i - 1] : self.send(direct_child_name)
    if nested_child_name
      return child_direct_child_node.child_node_range(nested_child_name)
    elsif child_direct_child_node
      return (
        Parser::Source::Range.new(
          '(string)',
          child_direct_child_node.loc.expression.begin_pos,
          child_direct_child_node.loc.expression.end_pos
        )
      )
    else
      raise Synvert::Core::MethodNotSupported,
            "child_node_range is not handled for #{debug_info}, child_name: #{child_name}"
    end
  end
end
