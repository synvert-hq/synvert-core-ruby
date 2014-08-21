# encoding: utf-8

module Synvert::Core
  # Rewriter::Helper provides some helper methods to make it easier to write a snippet.
  module Rewriter::Helper
    # Add receiver to code if necessary.
    #
    # @param code [String] old code
    # @return [String] new code
    #
    # @example
    #
    #   add_receiver_if_necessary("{{message}} {{arguments}}")
    #
    #   if current_node doesn't have a receiver, it returns "{{message}} {{arguments}}"
    #   if current_node has a receiver, it returns "{{receiver}}.{{message}} {{arguments}}"
    def add_receiver_if_necessary(code)
      if node.receiver
        "{{receiver}}.#{code}"
      else
        code
      end
    end

    # Remove leading and trailing brackets.
    #
    # @param code [String] old code
    # @return [String] new code
    #
    # @example
    #
    #   strip_brackets("(1..100)") #=> "1..100"
    def strip_brackets(code)
      code.sub(/^\((.*)\)$/) { $1 }
          .sub(/^\[(.*)\]$/) { $1 }
          .sub(/^{(.*)}$/) { $1 }
    end

    # Set current_node to node and process.
    #
    # @param node [Parser::AST::Node] node set to current_node
    # @yield process
    def process_with_node(node)
      self.current_node = node
      yield
      self.current_node = node
    end

    # Set current_node properly, process and set current_node back to original current_node.
    #
    # @param node [Parser::AST::Node] node set to current_node
    # @yield process
    def process_with_other_node(node)
      original_node = self.current_node
      self.current_node = node
      yield
      self.current_node = original_node
    end
  end
end
