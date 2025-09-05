# frozen_string_literal: true

Warning[:performance] = true if RUBY_VERSION >= '3.3'
Warning[:deprecated] = true
$VERBOSE = true

require 'warning'

Warning.process do |warning|
  next unless warning.include?(Dir.pwd)
  next if warning.include?('vendor/')

  raise "Warning in your code: #{warning}"
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'simplecov'

# Don't include unnecessary stuff into SimpleCov
SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/gems/'
  add_filter '/.bundle/'
  add_filter '/doc/'
  add_filter '/spec/'

  merge_timeout 3600
end

SimpleCov.minimum_coverage(95)

require 'bundler/setup'
require 'pidfd'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Only run tests on Linux where pidfd is supported
  config.filter_run_excluding requires_linux: true unless RUBY_PLATFORM.include?('linux')
end
