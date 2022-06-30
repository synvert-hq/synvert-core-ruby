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
  spec.homepage      = "https://github.com/xinminlabs/synvert-core-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0") +
                       %w[lib/synvert/core/node_query/lexer.rex.rb lib/synvert/core/node_query/parser.racc.rb]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "erubis"
  spec.add_runtime_dependency "node_query"
  spec.add_runtime_dependency "parser"
  spec.add_runtime_dependency "parser_node_ext"
end
