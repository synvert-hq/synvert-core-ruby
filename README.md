# synvert-core-ruby

<img src="https://synvert.net/img/logo_96.png" alt="logo" width="32" height="32" />

[![AwesomeCode Status for synvert-hq/synvert-core-ruby](https://awesomecode.io/projects/033f7f02-7b22-41c3-a902-fca37f1ec72a/status)](https://awesomecode.io/repos/synvert-hq/synvert-core-ruby)
[![Build Status](https://github.com/synvert-hq/synvert-core-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/synvert-hq/synvert-core-ruby/actions/workflows/main.yml)
[![Gem Version](https://img.shields.io/gem/v/synvert-core.svg)](https://rubygems.org/gems/synvert-core)

Synvert core provides a set of DSLs to rewrite (find and replace) ruby code. e.g.

```ruby
Synvert::Rewriter.new 'ruby', 'map_and_flatten_to_flat_map' do
  configure(parser: Synvert::PARSER_PARSER)

  description <<~EOS
    It converts `map` and `flatten` to `flat_map`

    ```ruby
    enum.map do
      # do something
    end.flatten
    ```

    =>

    ```ruby
    enum.flat_map do
      # do something
    end
    ```
  EOS

  within_files Synvert::ALL_RUBY_FILES + Synvert::ALL_RAKE_FILES do
    find_node '.send [receiver=.block [caller=.send[message=map]]] [message=flatten] [arguments.size=0]' do
      group do
        delete :message, :dot
        replace 'receiver.caller.message', with: 'flat_map'
      end
    end
  end
end
```

It also supports to add callbacks to visit ast nodes.

```ruby
Synvert::Helper.new 'ruby/parse' do |options|
  configure(parser: Synvert::PRISM_PARSER)

  with_configurations(number_of_workers: 1) do
    class_names = []
    within_file Synvert::ALL_RUBY_FILES do
      add_callback :class_node, at: 'start' do |node|
        class_names << node.name.to_source
      end
    end
    # class_names is an array of class names
  end
end

```

Want to see more examples, check out [synvert-snippets-ruby](https://github.com/synvert-hq/synvert-snippets-ruby).

Want to use the CLI, check out [synvert-ruby](https://github.com/synvert-hq/synvert-ruby).

DSLs are as follows

* [configure](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#configure-instance_method) - configure the rewriter
* [description](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#description-instance_method) - describe what the rewriter does
* [if_ruby](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#if_ruby-instance_method) - check if ruby version is greater than or equal to the specified ruby version
* [if_gem](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#if_gem-instance_method) - compare version of specified gem
* [within_files](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#within_files-instance_method) - find specified files
* [within_file](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#within_file-instance_method) - alias to within_files
* [add_file](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#add_file-instance_method) - add a new file
* [remove_file](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#remove_file-instance_method) - remove a file
* [helper_method](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#helper_method-instance_method) - define a helper method
* [add_snippet](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#add_snippet-instance_method) - call another rewriter
* [call_helper](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#call_helper-instance_method) - call a shared rewriter
* [with_configurations](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#with_configurations-instance_method) - execute a block of code with temporary configurations
* [save_data](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#save_data-instance_method) - save data
* [load_data](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#load_data-instance_method) - load data

Scopes:

* [within_node](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#within_node-instance_method) - recursively find matching ast nodes
* [with_node](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#with_node-instance_method) - alias to within_node
* [find_node](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#find_node-instance_method) - alias to within_node
* [goto_node](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#goto_node-instance_method) - go to a child node

Conditions:

* [if_exist_node](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#if_exist_node-instance_method) - check if matching node exist in the child nodes
* [unless_exist_node](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#unless_exist_node-instance_method) - check if matching node doesn't exist in the child nodes

Actions:

* [append](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#append-instance_method) - append the code to the bottom of current node body
* [prepend](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#prepend-instance_method) - prepend the code to the bottom of current node body
* [indent](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#indent-instance_method) - indent code
* [insert](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#insert-instance_method) - insert code
* [insert_after](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#insert_after-instance_method) - insert the code next to the current node
* [insert_before](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#insert_before-instance_method) - insert the code previous to the current node
* [replace](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#replace-instance_method) - replace the code of specified child nodes
* [delete](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#delete-instance_method) - delete the code in specified child nodes
* [remove](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#remove-instance_method) - remove the whole code of current node
* [wrap](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#wrap-instance_method) - wrap the current node with prefix and suffix code
* [replace_with](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#replace_with-instance_method) - replace the whole code of current node
* [warn](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#warn-instance_method) - warn message
* [replace_erb_stmt_with_expr](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#replace_erb_stmt_with_expr-instance_method) - replace erb stmt code to expr code
* [noop](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#noop-instance_method) - no operation
* [group](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#group-instance_method) - group actions
* [add_action](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#add_action-instance_method) - add custom action

Callbacks:

* [add_callback](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#add_callback-instance_method) - add callback when visiting ast nodes

Others:

* [wrap_with_quotes](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#wrap_with_quotes-instance_method) - wrap string code with single or double quotes
* [add_leading_spaces](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#add_leading_spaces-instance_method) - add leading spaces before the string code


Attributes:

* [file_path](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#file_path-instance_method) - current file path
* [node](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#node-instance_method) - current ast node
* [mutation_adapter](https://synvert-hq.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#mutation_adapter-instance_method) - [mutation adapter](https://synvert-hq.github.io/node-mutation-ruby/NodeMutation/Adapter.html) to get some helper methods
