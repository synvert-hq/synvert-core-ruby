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
    def initialize(instance, rules, options = {}, &block)
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

      matching_nodes =
        if @options[:direct]
          find_direct_matching_nodes(current_node)
        elsif @options[:recursive]
          find_recursive_matching_nodes(current_node)
        else
          find_matching_nodes(current_node)
        end
      @instance.process_with_node current_node do
        matching_nodes.each do |matching_node|
          @instance.process_with_node matching_node do
            @instance.instance_eval(&@block)
          end
        end
      end
    end

    private

    # Find the matching nodes only in current or direct children.
    def find_direct_matching_nodes(current_node)
      matching_nodes = []
      if current_node.is_a?(Parser::AST::Node)
        if current_node.type == :begin
          current_node.children.each { |child_node| matching_nodes << child_node if child_node.match?(@rules) }
        elsif current_node.match?(@rules)
          matching_nodes << current_node
        end
      else
        current_node.each { |child_node| matching_nodes << child_node if child_node.match?(@rules) }
      end
      matching_nodes
    end

    # Find matching nodes in all recursive children.
    def find_recursive_matching_nodes(current_node)
      matching_nodes = []
      if current_node.is_a?(Parser::AST::Node)
        matching_nodes << current_node if current_node.match?(@rules)
        current_node.recursive_children { |child_node| matching_nodes << child_node if child_node.match?(@rules) }
      else
        current_node.each do |node|
          matching_nodes << node if node.match?(@rules)
          node.recursive_children { |child_node| matching_nodes << child_node if child_node.match?(@rules) }
        end
      end
      matching_nodes
    end

    # Find matching nodes in recursive children but do not continue on matching nodes.
    def find_matching_nodes(current_node)
      matching_nodes = []
      if current_node.is_a?(Parser::AST::Node)
        if current_node.match?(@rules)
          matching_nodes << current_node
          return matching_nodes
        end
        current_node.recursive_children do |child_node|
          stop = nil
          if child_node.match?(@rules)
            matching_nodes << child_node
            stop = :stop
          end
          stop
        end
      else
        current_node.each do |node|
          if node.match?(@rules)
            matching_nodes << node
            next
          end
          node.recursive_children do |child_node|
            stop = nil
            if child_node.match?(@rules)
              matching_nodes << child_node
              stop = :stop
            end
            stop
          end
        end
      end
      matching_nodes
    end
  end
end
