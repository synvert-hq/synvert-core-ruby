# coding: utf-8
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'synvert/core/version'

Gem::Specification.new do |spec|
  spec.name          = "synvert-core"
  spec.version       = Synvert::Core::VERSION
  spec.authors       = ["Richard Huang"]
  spec.email         = ["flyerhzm@gmail.com"]
  spec.summary       = %q{convert ruby code to better syntax.}
  spec.description   = %q{convert ruby code to better syntax automatically.}
  spec.homepage      = "https://github.com/xinminlabs/synvert-core"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "parser", "~> 3.0.0"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "erubis"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
end
