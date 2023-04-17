# synvert-core-ruby

<img src="https://synvert.net/img/logo_96.png" alt="logo" width="32" height="32" />

[![AwesomeCode Status for xinminlabs/synvert-core-ruby](https://awesomecode.io/projects/033f7f02-7b22-41c3-a902-fca37f1ec72a/status)](https://awesomecode.io/repos/xinminlabs/synvert-core-ruby)
![Main workflow](https://github.com/xinminlabs/synvert-core-ruby/actions/workflows/main.yml/badge.svg)

Synvert core provides a set of DSLs to rewrite ruby code. e.g.

```ruby
Synvert::Rewriter.new 'factory_bot', 'convert_factory_girl_to_factory_bot' do
  description <<~EOS
    It converts FactoryGirl to FactoryBot

    ```ruby
    require 'factory_girl'
    require 'factory_girl_rails'
    ```

    =>

    ```ruby
    require 'factory_bot'
    require 'factory_bot_rails'
    ```

    ```ruby
    FactoryGirl.create(:user)
    FactoryGirl.build(:user)
    ```

    =>

    ```ruby
    FactoryBot.create(:user)
    FactoryBot.build(:user)
    ```
  EOS

  within_files Synvert::RAILS_TEST_FILES do
    find_node '.const[name=FactoryGirl]' do
      replace_with 'FactoryBot'
    end

    find_node ".send[receiver=nil][message=require][arguments.size=1][arguments.first='factory_girl']" do
      replace :arguments, with: "'factory_bot'"
    end

    with_node type: 'send', receiver: nil, message: 'require', arguments: { size: 1, first: "'factory_girl_rails'" } do
      replace :arguments, with: "'factory_bot_rails'"
    end
  end
end
```

Want to see more examples, check out [synvert-snippets-ruby](https://github.com/xinminlabs/synvert-snippets-ruby).

Want to use the CLI, check out [synvert-ruby](https://github.com/xinminlabs/synvert-ruby).

DSLs are as follows

* [configure](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#configure-instance_method) - configure the rewriter
* [description](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#description-instance_method) - describe what the rewriter does
* [if_ruby](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#if_ruby-instance_method) - check if ruby version is greater than or equal to the specified ruby version
* [if_gem](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#if_gem-instance_method) - compare version of specified gem
* [within_files](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#within_files-instance_method) - find specified files
* [within_file](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#within_file-instance_method) - alias to within_files
* [add_file](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#add_file-instance_method) - add a new file
* [remove_file](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#remove_file-instance_method) - remove a file
* [helper_method](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#helper_method-instance_method) - define a helper method
* [add_snippet](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#add_snippet-instance_method) - call another rewriter
* [redo_until_no_change](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter.html#redo_until_no_change-instance_method) - run the snippet until no change

Scopes:

* [within_node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#within_node-instance_method) - recursively find matching ast nodes
* [with_node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#with_node-instance_method) - alias to within_node
* [find_node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#find_node-instance_method) - alias to within_node
* [goto_node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#goto_node-instance_method) - go to a child node

Conditions:

* [if_exist_node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#if_exist_node-instance_method) - check if matching node exist in the child nodes
* [unless_exist_node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#unless_exist_node-instance_method) - check if matching node doesn't exist in the child nodes
* [if_only_exist_node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#if_only_exist_node-instance_method) - check if current node has only one child node and the child node matches

Actions:

* [append](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#append-instance_method) - append the code to the bottom of current node body
* [prepend](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#prepend-instance_method) - prepend the code to the bottom of current node body
* [indent](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#indent-instance_method) - indent code
* [insert](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#insert-instance_method) - insert code
* [insert_after](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#insert_after-instance_method) - insert the code next to the current node
* [insert_before](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#insert_before-instance_method) - insert the code previous to the current node
* [replace](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#replace-instance_method) - replace the code of specified child nodes
* [delete](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#delete-instance_method) - delete the code in specified child nodes
* [remove](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#remove-instance_method) - remove the whole code of current node
* [wrap](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#wrap-instance_method) - wrap the current node with prefix and suffix code
* [replace_with](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#replace_with-instance_method) - replace the whole code of current node
* [warn](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#warn-instance_method) - warn message
* [replace_erb_stmt_with_expr](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#replace_erb_stmt_with_expr-instance_method) - replace erb stmt code to expr code
* [noop](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#noop-instance_method) - no operation
* [add_action](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#add_action-instance_method) - add custom action

Others:

* [wrap_with_quotes](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#wrap_with_quotes-instance_method) - wrap string code with single or doulbe quotes
* [add_leading_spaces](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#add_leading_spaces-instance_method) - add leading spaces before the string code


Attributes:

* [file_path](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#file_path-instance_method) - current file path
* [node](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#node-instance_method) - current ast node
* [mutation_adapter](https://xinminlabs.github.io/synvert-core-ruby/Synvert/Core/Rewriter/Instance.html#mutation_adapter-instance_method) - [mutation adapter](https://xinminlabs.github.io/node-mutation-ruby/NodeMutation/Adapter.html) to get some helper methods
