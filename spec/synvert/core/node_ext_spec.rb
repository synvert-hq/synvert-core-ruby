# frozen_string_literal: true

require 'spec_helper'

describe Parser::AST::Node do
  describe '#name' do
    it 'gets for class node' do
      node = parse('class Synvert; end')
      expect(node.name).to eq parse('Synvert')

      node = parse('class Synvert::Rewriter::Instance; end')
      expect(node.name).to eq parse('Synvert::Rewriter::Instance')
    end

    it 'gets for module node' do
      node = parse('module Synvert; end')
      expect(node.name).to eq parse('Synvert')
    end

    it 'gets for def node' do
      node = parse('def current_node; end')
      expect(node.name).to eq :current_node
    end

    it 'gets for defs node' do
      node = parse('def self.current_node; end')
      expect(node.name).to eq :current_node
    end

    it 'gets for arg node' do
      node = parse('def test(foo); end')
      expect(node.arguments.first.name).to eq :foo
    end

    it 'gets for blockarg node' do
      node = parse('def test(&block); end')
      expect(node.arguments.first.name).to eq :block
    end

    it 'gets for const node' do
      node = parse('Synvert')
      expect(node.name).to eq :Synvert
    end

    it 'gets for lvar node' do
      node = parse("foo = 'bar'\nfoo").children[1]
      expect(node.name).to eq :foo
    end

    it 'gets for ivar node' do
      node = parse("@foo = 'bar'\n@foo").children[1]
      expect(node.name).to eq :@foo
    end

    it 'gets for cvar node' do
      node = parse("@@foo = 'bar'\n@@foo").children[1]
      expect(node.name).to eq :@@foo
    end

    it 'gets for mlhs node' do
      node = parse('var.each { |(param1, param2)| }')
      expect(node.arguments.first.name).to eq node.arguments.first
    end

    it 'gets for restarg node' do
      node = parse('object.each { |*entry| }')
      expect(node.arguments.first.name).to eq :entry
    end
  end

  describe '#parent_class' do
    it 'gets for class node' do
      node = parse('class Post < ActiveRecord::Base; end')
      expect(node.parent_class).to eq parse('ActiveRecord::Base')
    end
  end

  describe '#receiver' do
    it 'gets for send node' do
      node = parse('FactoryGirl.create :post')
      expect(node.receiver).to eq parse('FactoryGirl')
    end
  end

  describe '#message' do
    it 'gets for send node' do
      node = parse('FactoryGirl.create :post')
      expect(node.message).to eq :create
    end

    it 'gets for super node' do
      node = parse('super(params)')
      expect(node.message).to eq :super
    end

    it 'gets for zuper node' do
      node = parse('super do; end')
      expect(node.caller.message).to eq :super
    end
  end

  describe '#parent_const' do
    it 'gets for const node' do
      node = parse('Synvert::Node')
      expect(node.parent_const).to eq parse('Synvert')
    end

    it 'gets for const node at the root' do
      node = parse('::Node')
      expect(node.parent_const.type).to eq :cbase
    end

    it 'gets for const node with no parent' do
      node = parse('Node')
      expect(node.parent_const).to eq nil
    end
  end

  describe '#arguments' do
    it 'gets for def node' do
      node = parse('def test(foo, bar); foo + bar; end')
      expect(node.arguments.type).to eq :args
    end

    it 'gets for defs node' do
      node = parse('def self.test(foo, bar); foo + bar; end')
      expect(node.arguments.type).to eq :args
    end

    it 'gets for block node' do
      node = parse('RSpec.configure do |config|; end')
      expect(node.arguments.type).to eq :args
    end

    it 'gets for send node' do
      node = parse("FactoryGirl.create :post, title: 'post'")
      expect(node.arguments).to eq parse("[:post, title: 'post']").children
    end

    it 'gets for defined? node' do
      node = parse('defined?(Bundler)')
      expect(node.arguments).to eq [parse('Bundler')]
    end
  end

  describe '#caller' do
    it 'gets for block node' do
      node = parse('RSpec.configure do |config|; end')
      expect(node.caller).to eq parse('RSpec.configure')
    end
  end

  describe '#body' do
    it 'gets one line for block node' do
      node = parse('RSpec.configure do |config|; include EmailSpec::Helpers; end')
      expect(node.body).to eq [parse('include EmailSpec::Helpers')]
    end

    it 'gets multiple lines for block node' do
      node = parse('RSpec.configure do |config|; include EmailSpec::Helpers; include EmailSpec::Matchers; end')
      expect(node.body).to eq [parse('include EmailSpec::Helpers'), parse('include EmailSpec::Matchers')]
    end

    it 'gets empty for class node' do
      node = parse('class User; end')
      expect(node.body).to be_empty
    end

    it 'gets empty for module node' do
      node = parse('module Admin; end')
      expect(node.body).to be_empty
    end

    it 'gets one line for class node' do
      node = parse('class User; attr_accessor :email; end')
      expect(node.body).to eq [parse('attr_accessor :email')]
    end

    it 'gets one line for class node' do
      node = parse('class User; attr_accessor :email; attr_accessor :username; end')
      expect(node.body).to eq [parse('attr_accessor :email'), parse('attr_accessor :username')]
    end

    it 'gets for begin node' do
      node = parse('foo; bar')
      expect(node.body).to eq [parse('foo'), parse('bar')]
    end

    it 'gets for def node' do
      node = parse('def test; foo; bar; end')
      expect(node.body).to eq [parse('foo'), parse('bar')]
    end

    it 'gets for def node with empty body' do
      node = parse('def test; end')
      expect(node.body).to eq []
    end

    it 'gets for defs node' do
      node = parse('def self.test; foo; bar; end')
      expect(node.body).to eq [parse('foo'), parse('bar')]
    end

    it 'gets for def node with empty body' do
      node = parse('def self.test; end')
      expect(node.body).to eq []
    end
  end

  describe '#keys' do
    it 'gets for hash node' do
      node = parse("{:foo => :bar, 'foo' => 'bar'}")
      expect(node.keys).to eq [parse(':foo'), parse("'foo'")]
    end
  end

  describe '#values' do
    it 'gets for hash node' do
      node = parse("{:foo => :bar, 'foo' => 'bar'}")
      expect(node.values).to eq [parse(':bar'), parse("'bar'")]
    end
  end

  describe '#key?' do
    it 'gets true if key exists' do
      node = parse('{:foo => :bar}')
      expect(node.key?(:foo)).to be_truthy
    end

    it 'gets false if key does not exist' do
      node = parse('{:foo => :bar}')
      expect(node.key?('foo')).to be_falsey
    end
  end

  describe '#hash_value' do
    it 'gets value of specified key' do
      node = parse('{:foo => :bar}')
      expect(node.hash_value(:foo)).to eq parse(':bar')
    end

    it 'gets nil if key does not exist' do
      node = parse('{:foo => :bar}')
      expect(node.hash_value(:bar)).to be_nil
    end
  end

  describe '#key' do
    it 'gets for pair node' do
      node = parse("{:foo => 'bar'}").children[0]
      expect(node.key).to eq parse(':foo')
    end
  end

  describe '#value' do
    it 'gets for hash node' do
      node = parse("{:foo => 'bar'}").children[0]
      expect(node.value).to eq parse("'bar'")
    end
  end

  describe '#condition' do
    it 'gets for if node' do
      node = parse('if defined?(Bundler); end')
      expect(node.condition).to eq parse('defined?(Bundler)')
    end
  end

  describe '#left_value' do
    it 'gets for masgn' do
      node = parse('a, b = 1, 2')
      expect(node.left_value.to_source).to eq 'a, b'
    end

    it 'gets for lvasgn' do
      node = parse('a = 1')
      expect(node.left_value).to eq :a
    end

    it 'gets for ivasgn' do
      node = parse('@a = 1')
      expect(node.left_value).to eq :@a
    end

    it 'gets for cvasgn' do
      node = parse('@@a = 1')
      expect(node.left_value).to eq :@@a
    end

    it 'gets for or_asgn' do
      node = parse('a ||= 1')
      expect(node.left_value).to eq :a
    end

    it 'gets for and' do
      node = parse('foo && bar')
      expect(node.left_value).to eq parse('foo')
    end

    it 'gets for or' do
      node = parse('foo || bar')
      expect(node.left_value).to eq parse('foo')
    end
  end

  describe '#right_value' do
    it 'gets for masgn' do
      node = parse('a, b = 1, 2')
      expect(node.right_value).to eq parse('[1, 2]')
    end

    it 'gets for masgn' do
      node = parse('a, b = params')
      expect(node.right_value).to eq parse('params')
    end

    it 'gets for lvasgn' do
      node = parse('a = 1')
      expect(node.right_value).to eq parse('1')
    end

    it 'gets for ivasgn' do
      node = parse('@a = 1')
      expect(node.right_value).to eq parse('1')
    end

    it 'gets for cvasgn' do
      node = parse('@@a = 1')
      expect(node.right_value).to eq parse('1')
    end

    it 'gets for or_asgn' do
      node = parse('a ||= 1')
      expect(node.right_value).to eq parse('1')
    end

    it 'gets for and' do
      node = parse('foo && bar')
      expect(node.right_value).to eq parse('bar')
    end

    it 'gets for or' do
      node = parse('foo || bar')
      expect(node.right_value).to eq parse('bar')
    end
  end

  describe '#to_value' do
    it 'gets for int' do
      node = parse('1')
      expect(node.to_value).to eq 1
    end

    it 'gets for float' do
      node = parse('1.5')
      expect(node.to_value).to eq 1.5
    end

    it 'gets for string' do
      node = parse("'str'")
      expect(node.to_value).to eq 'str'
    end

    it 'gets for symbol' do
      node = parse(':str')
      expect(node.to_value).to eq :str
    end

    it 'gets for boolean' do
      node = parse('true')
      expect(node.to_value).to be_truthy
      node = parse('false')
      expect(node.to_value).to be_falsey
    end

    it 'gets for irange' do
      node = parse('(1..10)')
      expect(node.to_value).to eq(1..10)
    end

    it 'gets for erange' do
      node = parse('(1...10)')
      expect(node.to_value).to eq(1...10)
    end

    it 'gets for array' do
      node = parse("['str', :str]")
      expect(node.to_value).to eq ['str', :str]
    end
  end

  describe '#to_s' do
    it 'gets for mlhs node' do
      node = parse('var.each { |(param1, param2)| }')
      expect(node.arguments.first.to_s).to eq '(param1, param2)'
    end
  end

  describe '#filename' do
    it 'gets file name' do
      source = 'foobar'
      node = parse(source)
      expect(node.filename).to eq '(string)'
    end
  end

  describe '#to_source' do
    it 'gets for node' do
      source = 'params[:user][:email]'
      node = parse(source)
      expect(node.to_source).to eq 'params[:user][:email]'
    end
  end

  describe '#column' do
    it 'gets column number' do
      node = parse('  FactoryGirl.create :post')
      expect(node.column).to eq 2
    end
  end

  describe '#line' do
    it 'gets line number' do
      node = parse('foobar')
      expect(node.line).to eq 1
    end
  end

  describe 'key value by method_missing' do
    it 'gets for key value' do
      node = parse('{:foo => :bar}')
      expect(node.foo_value).to eq :bar

      node = parse("{'foo' => 'bar'}")
      expect(node.foo_value).to eq 'bar'

      expect(node.bar_value).to be_nil
    end
  end

  describe 'key value source by method_missing' do
    it 'gets for key value source' do
      node = parse('{:foo => :bar}')
      expect(node.foo_source).to eq ':bar'

      node = parse("{'foo' => 'bar'}")
      expect(node.foo_source).to eq "'bar'"

      expect(node.bar_source).to be_nil
    end
  end

  describe '#recursive_children' do
    it 'iterates all children recursively' do
      node = parse('class Synvert; def current_node; @node; end; end')
      children = []
      node.recursive_children { |child| children << child.type }
      expect(children).to be_include :const
      expect(children).to be_include :def
      expect(children).to be_include :args
      expect(children).to be_include :ivar
    end
  end

  describe '#match?' do
    it 'matches class name' do
      source = 'class Synvert; end'
      node = parse(source)
      expect(node).to be_match(type: 'class', name: 'Synvert')
    end

    it 'matches message with regexp' do
      source = 'User.find_by_login(login)'
      node = parse(source)
      expect(node).to be_match(type: 'send', message: /^find_by_/)
    end

    it 'matches arguments with symbol' do
      source = 'params[:user]'
      node = parse(source)
      expect(node).to be_match(type: 'send', receiver: 'params', message: '[]', arguments: [:user])
    end

    it 'matches pair key with symbol' do
      source = '{ type: :model }'
      node = parse(source).children[0]
      expect(node).to be_match(type: 'pair', key: :type)
    end

    it 'matches assign number' do
      source = 'at_least(0)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: [0])
    end

    it 'matches assign float' do
      source = 'at_least(1.5)'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: [1.5])
    end

    it 'matches arguments with string' do
      source = 'params["user"]'
      node = parse(source)
      expect(node).to be_match(type: 'send', receiver: 'params', message: '[]', arguments: ['user'])
    end

    it 'matches arguments with string 2' do
      source = 'params["user"]'
      node = parse(source)
      expect(node).to be_match(type: 'send', receiver: 'params', message: '[]', arguments: ["'user'"])
    end

    it 'matches arguments with string 3' do
      source = "{ notice: 'Welcome' }"
      node = parse(source)
      expect(node).to be_match(type: 'hash', notice_value: "'Welcome'")
    end

    it 'matches arguments any' do
      source = 'config.middleware.insert_after ActiveRecord::QueryCache, Lifo::Cache, page_cache: false'
      node = parse(source)
      expect(node).to be_match(type: 'send', arguments: { any: 'Lifo::Cache' })
    end

    it 'matches arguments with nested hash' do
      source = '{ user_id: user.id }'
      node = parse(source)
      expect(node).to be_match(type: 'hash', user_id_value: { type: 'send', receiver: { type: 'send', message: 'user' }, message: 'id' })
    end

    it 'matches arguments contain' do
      source = 'def slow(foo, bar, &block); end'
      node = parse(source)
      expect(node).to be_match(type: 'def', arguments: { contain: '&block' })
    end

    it 'matches not' do
      source = 'class Synvert; end'
      node = parse(source)
      expect(node).not_to be_match(type: 'class', name: { not: 'Synvert' })
    end

    it 'matches in' do
      source = 'FactoryBot.create(:user)'
      node = parse(source)
      expect(node).to be_match(type: 'send', message: { in: %i[create build] })
    end

    it 'matches not_in' do
      source = 'FactoryBot.create(:user)'
      node = parse(source)
      expect(node).not_to be_match(type: 'send', message: { not_in: %i[create build] })
    end
  end

  describe '#child_node_by_name' do
    context 'block node' do
      it 'checks caller' do
        node = parse('Factory.define :user do |user|; end')
        child_node = node.child_node_by_name(:caller)
        expect(child_node).to eq node.caller
      end

      it 'checks arguments' do
        node = parse('Factory.define :user do |user|; end')
        child_node = node.child_node_by_name(:arguments)
        expect(child_node).to eq node.arguments
      end

      it 'checks caller.receiver' do
        node = parse('Factory.define :user do |user|; end')
        child_node = node.child_node_by_name('caller.receiver')
        expect(child_node).to eq node.caller.receiver
      end

      it 'checks caller.message' do
        node = parse('Factory.define :user do |user|; end')
        child_node = node.child_node_by_name('caller.message')
        expect(child_node).to eq node.caller.message
      end
    end

    context 'array' do
      it 'checks array by index' do
        node = parse('factory :admin, class: User do; end')
        child_node = node.child_node_by_name('caller.arguments.2')
        expect(child_node).to eq node.caller.arguments[1]
      end

      it 'checks array by method' do
        node = parse('factory :admin, class: User do; end')
        child_node = node.child_node_by_name('caller.arguments.second')
        expect(child_node).to eq node.caller.arguments[1]
      end

      it "checks array' value" do
        node = parse('factory :admin, class: User do; end')
        child_node = node.child_node_by_name('caller.arguments.second.class_value')
        expect(child_node).to eq node.caller.arguments[1].class_value
      end
    end
  end

  describe '#child_node_range' do
    context 'block node' do
      it 'checks caller' do
        node = parse('Factory.define :user do |user|; end')
        range = node.child_node_range(:caller)
        expect(range.to_range).to eq(0...20)
      end

      it 'checks arguments' do
        node = parse('Factory.define :user do |user|; end')
        range = node.child_node_range(:arguments)
        expect(range.to_range).to eq(25...29)
      end

      it 'checks pipes' do
        node = parse('Factory.define :user do |user|; end')
        range = node.child_node_range(:pipes)
        expect(range.to_range).to eq(24...30)
      end

      it 'checks caller.receiver' do
        node = parse('Factory.define :user do |user|; end')
        range = node.child_node_range('caller.receiver')
        expect(range.to_range).to eq(0...7)
      end

      it 'checks caller.message' do
        node = parse('Factory.define :user do |user|; end')
        range = node.child_node_range('caller.message')
        expect(range.to_range).to eq(8...14)
      end
    end

    context 'class node' do
      it 'checks name' do
        node = parse('class Post < ActiveRecord::Base; end')
        range = node.child_node_range(:name)
        expect(range.to_range).to eq(6...10)
      end

      it 'checks parent_class' do
        node = parse('class Post < ActiveRecord::Base; end')
        range = node.child_node_range(:parent_class)
        expect(range.to_range).to eq(13...31)

        node = parse('class Post; end')
        range = node.child_node_range(:parent_class)
        expect(range).to be_nil
      end
    end

    context 'def node' do
      it 'checks name' do
        node = parse('def foo(bar); end')
        range = node.child_node_range(:name)
        expect(range.to_range).to eq(4...7)
      end

      it 'checks arguments' do
        node = parse('def foo(bar); end')
        range = node.child_node_range(:arguments)
        expect(range.to_range).to eq(8...11)
      end

      it 'checks parentheses' do
        node = parse('def foo(bar); end')
        range = node.child_node_range(:parentheses)
        expect(range.to_range).to eq(7...12)
      end
    end

    context 'defs node' do
      it 'checks self' do
        node = parse('def self.foo(bar); end')
        range = node.child_node_range(:self)
        expect(range.to_range).to eq(4...8)
      end

      it 'checks dot' do
        node = parse('def self.foo(bar); end')
        range = node.child_node_range(:dot)
        expect(range.to_range).to eq(8...9)
      end

      it 'checks name' do
        node = parse('def self.foo(bar); end')
        range = node.child_node_range(:name)
        expect(range.to_range).to eq(9...12)
      end

      it 'checks arguments' do
        node = parse('def self.foo(bar); end')
        range = node.child_node_range(:arguments)
        expect(range.to_range).to eq(13...16)
      end

      it 'checks parentheses' do
        node = parse('def self.foo(bar); end')
        range = node.child_node_range(:parentheses)
        expect(range.to_range).to eq(12...17)
      end
    end

    context 'send node' do
      it 'checks receiver' do
        node = parse('foo.bar(test)')
        range = node.child_node_range(:receiver)
        expect(range.to_range).to eq(0...3)

        node = parse('foobar(test)')
        range = node.child_node_range(:receiver)
        expect(range).to be_nil
      end

      it 'checks dot' do
        node = parse('foo.bar(test)')
        range = node.child_node_range(:dot)
        expect(range.to_range).to eq(3...4)

        node = parse('foobar(test)')
        range = node.child_node_range(:dot)
        expect(range).to be_nil
      end

      it 'checks message' do
        node = parse('foo.bar(test)')
        range = node.child_node_range(:message)
        expect(range.to_range).to eq(4...7)

        node = parse('foo.bar = test')
        range = node.child_node_range(:message)
        expect(range.to_range).to eq(4...9)

        node = parse('foobar(test)')
        range = node.child_node_range(:message)
        expect(range.to_range).to eq(0...6)
      end

      it 'checks arguments' do
        node = parse('foo.bar(test)')
        range = node.child_node_range(:arguments)
        expect(range.to_range).to eq(8...12)

        node = parse('foobar(test)')
        range = node.child_node_range(:arguments)
        expect(range.to_range).to eq(7...11)

        node = parse('foo.bar')
        range = node.child_node_range(:arguments)
        expect(range).to be_nil
      end

      it 'checks parentheses' do
        node = parse('foo.bar(test)')
        range = node.child_node_range(:parentheses)
        expect(range.to_range).to eq(7...13)

        node = parse('foobar(test)')
        range = node.child_node_range(:parentheses)
        expect(range.to_range).to eq(6...12)

        node = parse('foo.bar')
        range = node.child_node_range(:parentheses)
        expect(range).to be_nil
      end
    end

    context 'array' do
      it 'checks array by index' do
        node = parse('factory :admin, class: User do; end')
        range = node.child_node_range('caller.arguments.2')
        expect(range.to_range).to eq(16...27)
      end

      it 'checks array by method' do
        node = parse('factory :admin, class: User do; end')
        range = node.child_node_range('caller.arguments.second')
        expect(range.to_range).to eq(16...27)
      end

      it "checks array' value" do
        node = parse('factory :admin, class: User do; end')
        range = node.child_node_range('caller.arguments.second.class_value')
        expect(range.to_range).to eq(23...27)
      end
    end
  end

  describe '#rewritten_source' do
    it 'does not rewrite with unknown method' do
      source = 'class Synvert; end'
      node = parse(source)
      expect(node.rewritten_source('{{foobar}}')).to eq '{{foobar}}'
    end

    it 'rewrites with node known method' do
      source = 'class Synvert; end'
      node = parse(source)
      expect(node.rewritten_source('{{name}}')).to eq 'Synvert'
    end

    it 'rewrites for arguments' do
      source = 'test { |a, b| }'
      node = parse(source)
      expect(node.rewritten_source('{{arguments}}')).to eq 'a, b'
    end

    it 'rewrites array with multi line given as argument for method' do
      source = <<~EOS.strip
        long_name_method([
          1,
          2,
          3
        ])
      EOS

      node = parse(source)
      expect(node.rewritten_source('{{arguments}}')).to eq <<~EOS.strip
        [
          1,
          2,
          3
        ]
      EOS
    end
  end

  describe '#strip_curly_braces' do
    context 'hash node' do
      it 'removes curly braces' do
        node = parse("{ foo: 'bar' }")
        expect(node.strip_curly_braces).to eq("foo: 'bar'")
      end
    end

    context 'other node' do
      it 'do nothing' do
        node = parse("'foobar'")
        expect(node.strip_curly_braces).to eq("'foobar'")
      end
    end
  end

  describe '#wrap_curly_braces' do
    context 'hash node' do
      it 'adds curly braces' do
        node = parse("test(foo: 'bar')").arguments.first
        expect(node.to_source).to eq("foo: 'bar'")
        expect(node.wrap_curly_braces).to eq("{ foo: 'bar' }")
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse("'foobar'")
        expect(node.wrap_curly_braces).to eq("'foobar'")
      end
    end
  end

  describe '#to_single_quote' do
    context 'str node' do
      it 'converts double quote to single quote' do
        node = parse('"foobar"')
        expect(node.to_source).to eq '"foobar"'
        expect(node.to_single_quote).to eq "'foobar'"
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse(':foobar')
        expect(node.to_single_quote).to eq ':foobar'
      end
    end
  end

  describe '#to_symbol' do
    context 'str node' do
      it 'converts string to symbol' do
        node = parse("'foobar'")
        expect(node.to_symbol).to eq ':foobar'
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse(':foobar')
        expect(node.to_symbol).to eq ':foobar'
      end
    end
  end

  describe '#to_string' do
    context 'sym node' do
      it 'converts symbol to string' do
        node = parse(':foobar')
        expect(node.to_string).to eq 'foobar'
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse("'foobar'")
        expect(node.to_string).to eq "'foobar'"
      end
    end
  end

  describe '#to_lambda_literal' do
    context 'lambda node' do
      it 'converts to lambda literal without arguments' do
        node = parse('lambda { foobar }')
        expect(node.to_lambda_literal).to eq('-> { foobar }')
      end

      it 'converts to lambda literal with arguments' do
        node = parse('lambda { |x, y| foobar }')
        expect(node.to_lambda_literal).to eq('->(x, y) { foobar }')
      end
    end

    context 'other node' do
      it 'does nothing' do
        node = parse(':foobar')
        expect(node.to_lambda_literal).to eq ':foobar'
      end
    end
  end
end
