# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'synvert/core/version'

Gem::Specification.new do |spec|
  spec.name          = "synvert-core"
  spec.version       = Synvert::Core::VERSION
  spec.authors       = ["Richard Huang"]
  spec.email         = ["flyerhzm@gmail.com"]
  spec.summary       = 'convert ruby code to better syntax.'
  spec.description   = 'convert ruby code to better syntax automatically.'
  spec.homepage      = "https://github.com/synvert-hq/synvert-core-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "node_query", ">= 1.15.4"
  spec.add_runtime_dependency "node_mutation", ">= 1.24.4"
  spec.add_runtime_dependency "node_visitor", ">= 1.1.0"
  spec.add_runtime_dependency "parser"
  spec.add_runtime_dependency "parser_node_ext", ">= 1.4.2"
  spec.add_runtime_dependency "syntax_tree"
  spec.add_runtime_dependency "syntax_tree_ext", ">= 0.9.2"
  spec.add_runtime_dependency "prism"
  spec.add_runtime_dependency "prism_ext", ">= 0.4.2"
  spec.add_runtime_dependency "parallel"

  spec.add_development_dependency "simplecov"
end
