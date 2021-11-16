# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'synvert/core'

require 'coveralls'
Coveralls.wear!

Dir[File.join(File.dirname(__FILE__), 'support', '*')].each { |path| require path }

RSpec.configure do |config|
  config.include ParserHelper

  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end
