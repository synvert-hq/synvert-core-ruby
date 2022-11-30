# CHANGELOG

## 1.15.0 (2022-11-30)

* Load snippet from github

## 1.14.2 (2022-11-19)

* Specify `node_query`, `node_mutation` and `parser_node_ext` versions

## 1.14.1 (2022-10-26)

* Abstract `AnyValue` to NodeQuery

## 1.14.0 (2022-10-25)

* `insert_after` and `insert_before` accepts `to` option
* Add `configure` dsl to configure the strategy

## 1.13.1 (2022-10-17)

* Do not send hash to keyword arguments

## 1.13.0 (2022-10-17)

* Add `insert_before` dsl
* Update `insert_after` to reuse `NodeMutation#insert`

## 1.12.0 (2022-10-14)

* Condition accepts both nql and rules
* Make `find_node` as an alias to `within_node`
* Remove skip files only once

## 1.11.0 (2022-10-11)

* Add `Configuration.number_of_workers`
* Test rewriter in parallel

## 1.10.1 (2022-10-09)

* Do not reset `@options`
* `Rewriter.fetch` does not raise error if rewriter not found

## 1.10.0 (2022-10-09)

* Eval snippet by http url, file path or snippet name
* Remove `execute_command` option
* Remove `Rewriter.call`
* Remove `Rewriter.execute`

## 1.9.2 (2022-10-03)

* Fix `test` in sub_snippets

## 1.9.1 (2022-09-23)

* Read / write absolute path

## 1.9.0 (2022-09-20)

* Add `noop` dsl

## 1.8.1 (2022-09-17)

* Fix test snippet, return test results

## 1.8.0 (2022-09-17)

* Rename config `path` to `root_path`
* Rename config `skip_files` to `skip_paths`
* Add config `only_paths`
* Change dir to `root_path`

## 1.7.0 (2022-09-16)

* Add `Rewriter#test`
* Use option `run_instance` instead of `sandbox`

## 1.6.0 (2022-09-15)

* Make use of `NodeQuery` to query nodes
* Remove `Node#to_hash`
* Downgrade `activesupport` to < 7.0.0

## 1.5.0 (2022-07-02)

* Abstract `node_query`
* Abstract `node_mutation`
* Abstract `parser_node_ext`

## 1.4.0 (2022-05-21)

* Drop support `:first-child` and `:last-child`
* Redefine goto scope in nql
* Fix shift/reduce conflict

## 1.3.1 (2022-05-14)

* Add `add_comma` option to remove extra comma

## 1.3.0 (2022-05-12)

* Support `*=`, `^=` and `$=` operators
* Simplify RELATIONSHIP parser
* Rewrite compiler, let the selector to query nodes

## 1.2.1 (2022-05-01)

* Selector always after a node type in NQL
* Define `pairs` method for `hash` ndoe

## 1.2.0 (2022-04-29)

* Remove comma in NQL array value
* Parse pseduo class without selector in NQL
* Parse multiple goto scope in NQL
* Parse `nil?` in NQL

## 1.1.1 (2022-04-27)

* Parse empty string properly in node query language
* Parse `[]` and `[]=` properly in node query language

## 1.1.0 (2022-04-26)

* Dynamic define Node methods by `TYPE_CHILDREN` const
* Add `Node#to_hash`
* Parse empty string in node query language
* Identifier value can contain `?`, `<`, `=`, `>` in node query language

## 1.0.0 (2022-04-25)

* Introduce new node query language
* Drop ruby 2.5 support

## 0.64.0 (2022-04-02)

* Read absolute path of Gemfile.lock
* Remove unused `Node#to_s`
* Yardoc comments
* Drop `within_direct_node(rules)`, use `within_node(rules, { direct: true })` instead

## 0.63.0 (2022-02-26)

* Add `to` option to `InsertAction`
* Add `gt`, `gte`, `lt` and `lte` rules

## 0.62.0 (2021-12-24)

* Support `csend` node
* Restrict `activesupport` version to `~> 6`
* Fix `prepend` action for `def` and `defs` nodes
* Fix `append` action for `def` and `defs` nodes

## 0.61.0 (2021-12-10)

* Add `Node#child_node_by_name`
* Fix `Node#child_node_range` for array

## 0.60.0 (2021-12-02)

* Add `to_string` to `sym` node

## 0.59.0 (2021-11-17)

* Use option `stop_when_match` instead of `recursive`
* Add file pattern constants
* Instance supports array of file patterns
* Return block value by `next`
* Add `Node#filename` method

## 0.58.0 (2021-10-23)

* Support `left_value` and `right_value` for `and` and `or` node
* Rewrite `within_node` and `within_direct_node`, `WithinScope` accepts `recursive` and `direct` options

## 0.57.0 (2021-10-02)

* Compare ruby version in `.ruby-version` or `.rvmrc`
* Support `left_value` and `right_value` for `casgn` node
* Refactor - `calculate_position` to set `begin_pos` and `end_pos`
* Abstract `squeeze_spaces` and `squeeze_lines`
* Remove unused comma after delete/remove action
* Handle array child node in `childNodeRange`

## 0.56.0 (2021-09-14)

* Support `name` for `:lvar`, `:ivar`, `:cvar`
* Delete one more space if two spaces left

## 0.55.0 (2021-09-11)

* Add `Configuration.show_run_process`
* Fix remove action `begin_pos` and `end_pos`
* Fix `nil` match
* Rewrite `remove` action

## 0.54.0 (2021-08-28)

* Change `goto_scope` param from array to string

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
