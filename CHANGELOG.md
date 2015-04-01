# CHANGELOG

## 0.8.2

* Fix rewritten indent when number of lines and arguments are equal

## 0.8.1

* Fix match_value between symbol and string

## 0.8.0 (2014-10-26)

* Add line method to ast node
* Add add_arguments_with_parenthesis_if_necessary helper method
* Fix left_value and right_value node attribute
* Print warn when file was not parsed correctly
* Handle indent for node array source
* Rescue NoMethodError and output node debug info

## 0.7.0 (2014-09-29)

* Add debug info for MethodNotSupported error.
* Add left_value and right_vaue ext to ast node
* Add arguments for def and defs nodes
* Add name for arg and blockarg nodes
* Remove trailing whitespaces in rewritten code
* Rewriter.available always returns a hash
* Support ArgumentsNode in rewritten_source

## 0.6.0 (2014-09-01)

* Add goto_node dsl
* Add ArgumentsNode to handle args both as a node and as an array
* Add body for :defs node
* Raise RewriterNotFound if rewriter not found
* Remove Rewriter::Instance class methods current and current_source

## 0.5.0 (2014-08-21)

* Add group to rewriter
* Add parent_class for :class node
* Add Rewriter::Helper module to provide common helper methods.
* Fix indent for append and replace_with action
* Cache file source and ast

## 0.4.0 (2014-07-26)

* Add erb support
* Add replace_erb_stmt_with_expr dsl
* Improve Parser::AST::Node#to_value

## 0.3.0 (2014-07-12)

* Rename node.source(instance) to node.to_source
* Add has_key? and hash_value helper methods for hash node
* Fix Instance#check_conflict_actions

## 0.2.0 (2014-05-16)

* Add remove_file dsl
* Add warn dsl
* Return empty array if no available rewriters

## 0.1.0 (2014-05-04)

* Abstract from synvert
