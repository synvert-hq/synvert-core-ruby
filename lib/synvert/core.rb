# frozen_string_literal: true

require 'synvert/core/version'
require 'bundler'
require 'parser'
require 'parser/current'
require 'ast'
require 'active_support/core_ext/object'
require 'erubis'
require 'synvert/core/node_ext'

module Synvert
  module Core
    autoload :Configuration, 'synvert/core/configuration'
    autoload :Rewriter, 'synvert/core/rewriter'
    autoload :Engine, 'synvert/core/engine'
    autoload :RewriterNotFound, 'synvert/core/exceptions'
    autoload :GemfileLockNotFound, 'synvert/core/exceptions'
    autoload :MethodNotSupported, 'synvert/core/exceptions'
  end
end

module Synvert
  Rewriter = Core::Rewriter
end
