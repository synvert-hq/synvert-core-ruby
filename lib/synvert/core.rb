require "synvert/core/version"

# coding: utf-8
require "synvert/core/version"
require 'bundler'
require 'parser'
require 'parser/current'
require 'ast'
require 'active_support/inflector'
require 'synvert/core/node_ext'

module Synvert
  module Core
    autoload :Configuration, 'synvert/core/configuration'
    autoload :Rewriter, 'synvert/core/rewriter'
    autoload :RewriterNotFound, 'synvert/core/exceptions'
    autoload :GemfileLockNotFound, 'synvert/core/exceptions'
    autoload :MethodNotSupported, 'synvert/core/exceptions'
  end
end

module Synvert
  Rewriter = Core::Rewriter
end
