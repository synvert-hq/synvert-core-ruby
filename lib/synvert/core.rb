# frozen_string_literal: true

require 'synvert/core/version'
require 'active_support'
require 'active_support/core_ext'
require 'node_query'
require 'node_mutation'

module Synvert
  module Core
    autoload :Configuration, 'synvert/core/configuration'
    autoload :Rewriter, 'synvert/core/rewriter'
    autoload :Helper, 'synvert/core/helper'
    autoload :Engine, 'synvert/core/engine'
    autoload :Utils, 'synvert/core/utils'
    autoload :Strategy, 'synvert/core/strategy'
    autoload :Errors, 'synvert/core/errors'
  end
end

module Synvert
  Rewriter = Core::Rewriter
  Helper = Core::Helper
  Strategy = Core::Strategy

  ALL_RUBY_FILES = %w[**/*.rb]
  ALL_ERB_FILES = %w[**/*.erb]
  ALL_HAML_FILES = %w[**/*.haml]
  ALL_SLIM_FILES = %w[**/*.slim]
  ALL_RAKE_FILES = %w[**/*.rake]
  ALL_FILES = ALL_RUBY_FILES + ALL_ERB_FILES + ALL_HAML_FILES + ALL_SLIM_FILES + ALL_RAKE_FILES

  RAILS_APP_FILES = %w[app/**/*.rb engines/*/app/**/*.rb]
  RAILS_CONTROLLER_FILES = %w[app/controllers/**/*.rb engines/*/app/controllers/**/*.rb]
  RAILS_JOB_FILES = %w[app/jobs/**/*.rb engines/*/app/jobs/**/*.rb]
  RAILS_OBSERVER_FILES = %w[app/observers/**/*.rb engines/*/app/observers/**/*.rb]
  RAILS_HELPER_FILES = %w[app/helpers/**/*.rb]
  RAILS_LIB_FILES = %w[lib/**/*.rb engines/*/lib/**/*.rb]
  RAILS_MAILER_FILES = %w[app/mailers/**/*.rb engines/*/app/mailers/**/*.rb]
  RAILS_MIGRATION_FILES = %w[db/migrate/**/*.rb engines/*/db/migrate/**/*.rb]
  RAILS_MODEL_FILES = %w[app/models/**/*.rb engines/*/app/models/**/*.rb]
  RAILS_ROUTE_FILES = %w[
    config/routes.rb
    config/routes/**/*.rb
    engines/*/config/routes.rb
    engines/*/config/routes/**/*.rb
  ]
  RAILS_VIEW_FILES = ALL_ERB_FILES + ALL_HAML_FILES + ALL_SLIM_FILES

  RAILS_CONTROLLER_TEST_FILES = %w[
    test/functional/**/*.rb
    test/controllers/**/*.rb
    engines/*/test/functional/**/*.rb
    engines/*/test/controllers/**/*.rb
    spec/functional/**/*.rb
    spec/controllers/**/*.rb
    engines/*/spec/functional/**/*.rb
    engines/*/spec/controllers/**/*.rb
  ]
  RAILS_INTEGRATION_TEST_FILES = %w[test/integration/**/*.rb spec/integration/**/*.rb]
  RAILS_MODEL_TEST_FILES = %w[
    test/unit/**/*.rb
    engines/*/test/unit/**/*.rb
    test/models/**/*.rb
    engines/*/test/models/**/*.rb
    spec/models/**/*.rb
    engines/*/spec/models/**/*.rb
  ]

  RAILS_FACTORY_FILES = %w[test/factories/**/*.rb spec/factories/**/*.rb]
  RAILS_RSPEC_FILES = %w[spec/**/*.rb engines/*/spec/**/*.rb]
  RAILS_MINITEST_FILES = %w[test/**/*.rb engines/*/test/**/*.rb]
  RAILS_CUCUMBER_FILES = %w[features/**/*.rb]
  RAILS_TEST_FILES = RAILS_MINITEST_FILES + RAILS_RSPEC_FILES + RAILS_CUCUMBER_FILES

  PARSER_PARSER = 'parser'
  SYNTAX_TREE_PARSER = 'syntax_tree'
end
