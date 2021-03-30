# CHANGELOG

## 0.26.0 (2021-03-30)

* attr_reader ruby_version and gem_spec
* Add `replace` action

## 0.25.0 (2021-03-23)

* Use `Gem::Dependency#match?` to check gem version

## 0.24.0 (2021-03-17)

* Rename helper method `has_key?` to `key?`

## 0.23.0 (2021-03-14)

* Accept a node as goto_node argument

## 0.22.0 (2021-03-13)

* Track `affected_files` for rewriter
* Fix `find_matching_nodes` for `current_node`

## 0.21.0 (2021-02-25)

* Set `env['BUNDLE_GEMFILE']` before parsing `Gemfile.lock`
* Add `Rewriter::RubyVersion` test
* Add `reject_keys_from_hash` helper method

## 0.20.0 (2021-02-15)

* Call snippet in sandbox mode

## 0.19.0 (2021-02-07)

* Simplify `Configuration`

## 0.18.0 (2021-02-07)

* Add `Rewriter.execute`

## 0.17.0 (2021-01-29)

* Ignore `gem_spec` check if `Gemfile.lock` does not eixst

## 0.16.0 (2021-01-17)

* Use parser 3.0.0
* Fix magic number
* Add `within_direct_node` scope

## 0.15.0 (2018-05-23)

* Use parser 2.5.1.1

## 0.14.0 (2017-05-10)

* Add helper add_curly_brackets_if_necessary
* Add name for restarg node
* Add message for zsuper node

## 0.13.0 (2017-04-15)

* Add message for super node
* Add name and to_s for mlhs node

## 0.12.0 (2017-02-18)

* Use parser 2.4.0.0
* Add parent_const accessor for constant nodes with a namespace
* Warning if add_file already exists and make sure directory exists for add_file

## 0.11.0 (2016-07-31)

* Add options to Rewriter::Instance
* Add sort_by option to Rewriter::Instance

## 0.10.0 (2016-07-31)

* Use parser 2.3.1.2
* Add options to Rewriter::Action
* Add autoindent option to Rewriter::Action

## 0.9.0 (2015-12-23)

* Add if_ruby dsl
* Fix rewritten indent when number of lines and arguments are equal
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
