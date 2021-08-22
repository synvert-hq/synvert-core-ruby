# CHANGELOG

## 0.53.0 (2021-08-22)

* Fix nested child in Node#child_node_range
* Rename synvert-core to synvert-core-ruby

## 0.52.0 (2021-08-21)

* ``Node#child_node_range`` supports nested child
* Require `fileutils`
* Rename `Node#indent` to `Node#column`

## 0.51.0 (2021-08-12)

* Add `wrap` action
* Add new dsl `redo_until_no_change`

## 0.50.0 (2021-08-11)

* Support `:module` in `body`
* Fix symbol match

## 0.49.0 (2021-08-04)

* Support :erange in to_value
* Do not use to_value in match_value?

## 0.48.0 (2021-08-01)

* Force to read file as utf-8
* Add logo

## 0.47.0 (2021-07-28)

* Add `to_single_quote` to `str` node
* Add `to_symbol` to `str` node
* Add `to_lambda_literal` to `lambda` node

## 0.46.0 (2021-07-25)

* Add `strip_curly_braces` and `wrap_curly_braces` for `hash` node
* Simplify symbol `match_value?`
* Unwrap quote when matching string value

## 0.45.0 (2021-07-22)

* Handle `nil` child node for `begin_pos` and `end_pos`
* Remove `Rewriter::Instance` options

## 0.44.0 (2021-07-19)

* Return rewrtier after executing snippet
* `left_value` and `right_value` support `or_asgn` node
* `child_node_range` supports send `parentheses`

## 0.42.0 (2021-07-11)

* Match string with quote
* `match_value?` returns true if actual and expected are the same

## 0.41.0 (2021-06-24)

* Remove unused autoindent option
* Add `insert 'xxx', at: 'beginning'`

## 0.40.0 (2021-06-23)

* Rewrite `insert` action

## 0.39.0 (2021-06-23)

* Add `prepend` action instead of `insert`

## 0.38.0 (2021-06-21)

* Add `xxx_source` for `hash` node

## 0.36.0 (2021-06-21)

* Require `active_support/core_ext/array`

## 0.35.0 (2021-05-17)

* Add `contain` rule

## 0.34.0 (2021-05-16)

* `child_node_name` supports [:def, :parentheses] and [:defs, :parentheses]
* Rename `pipe` to `pipes`

## 0.33.0 (2021-05-10)

* Add `body` for `class` node

## 0.32.0 (2021-05-07)

* Remove `ArgumentsNode`

## 0.31.0 (2021-04-27)

* Add `in` and `not_in` rules

## 0.30.0 (2021-04-26)

* `goto_node` accepts multiple child node names
* Match any_value

## 0.29.0 (2021-04-25)

* Make `child_name_range` support [:block, :pipe]
* Get key value for hash node

## 0.28.0 (2021-04-07)

* Make `child_name_range` support all dsl nodes
* Make `replace` action support multi child names
* Fix `delete` action arguments

## 0.27.0 (2021-03-31)

* Support `:class` in `child_node_range`
* Add `delete` action

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
