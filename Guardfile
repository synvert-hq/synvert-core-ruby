# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('lib/synvert/core/node_query/lexer.rex.rb') { 'spec/synvert/core/node_query/lexer_spec.rb'  }
  watch('lib/synvert/core/node_query/compiler.rb') { 'spec/synvert/core/node_query/parser_spec.rb'  }
  watch(%r{^lib/synvert/core/node_query/compiler/.*\.rb$}) { 'spec/synvert/core/node_query/parser_spec.rb'  }
  watch('lib/synvert/core/node_query/parser.racc.rb') { 'spec/synvert/core/node_query/parser_spec.rb'  }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard :rake, task: 'generate' do
  watch('lib/synvert/core/node_query/lexer.rex')
  watch('lib/synvert/core/node_query/parser.y')
end
