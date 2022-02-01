# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'synvert/core'

Dir[File.join(File.dirname(__FILE__), 'support', '*')].each do |path|
  require path
end

RSpec.configure do |config|
  config.include ParserHelper

  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end
