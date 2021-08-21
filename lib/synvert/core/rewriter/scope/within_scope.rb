# frozen_string_literal: true

module Synvert::Core
  # WithinScope finds out nodes which match rules, then changes its scope to matching node.
  class Rewriter::WithinScope < Rewriter::Scope
    # Initialize a scope
    #
    # @param instance [Synvert::Core::Rewriter::Instance]
    # @param rules [Hash]
    # @param options [Hash]
    # @param block [Block]
    def initialize(instance, rules, options = { recursive: true }, &block)
      @instance = instance
      @rules = rules
      @options = options
      @block = block
    end

    # Find out the matching nodes.
    # It checks the current node and iterates all child nodes,
    # then run the block code on each matching node.
    def process
      current_node = @instance.current_node
      return unless current_node

      matching_nodes = find_matching_nodes(current_node)
      @instance.process_with_node current_node do
        matching_nodes.each do |matching_node|
          @instance.process_with_node matching_node do
            @instance.instance_eval(&@block)
          end
        end
      end
    end

    private

    def find_matching_nodes(current_node)
      matching_nodes = []
      if @options[:recursive]
        if current_node.is_a?(Parser::AST::Node)
          matching_nodes << current_node if current_node.match? @rules
          current_node.recursive_children do |child_node|
            matching_nodes << child_node if child_node.match? @rules
          end
        else
          current_node.each do |node|
            matching_nodes << node if node.match? @rules
            node.recursive_children do |child_node|
              matching_nodes << child_node if child_node.match? @rules
            end
          end
        end
      elsif current_node.is_a?(Parser::AST::Node)
        if current_node.type == :begin
          current_node.children.each do |child_node|
            matching_nodes << child_node if child_node.match? @rules
          end
        elsif current_node.match? @rules
          matching_nodes << current_node
        end
      else
        current_node.each do |child_node|
          matching_nodes << child_node if child_node.match? @rules
        end
      end
      matching_nodes
    end
  end
end
