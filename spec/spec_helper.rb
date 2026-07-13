# frozen_string_literal: true

require "warning"

$VERBOSE = true

if Warning.respond_to?(:categories)
  (Warning.categories - %i[experimental]).each do |cat|
    Warning[cat] = true
  end
end

Warning.process do |warning|
  next unless warning.include?(Dir.pwd)
  next if warning.include?("vendor/")

  raise "Warning in your code: #{warning}"
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "simplecov"

# Don't include unnecessary stuff into SimpleCov
SimpleCov.start do
  skip "/vendor/"
  skip "/gems/"
  skip "/.bundle/"
  skip "/doc/"
  skip "/spec/"

  merge_timeout 3600
end

SimpleCov.minimum_coverage(95) unless RUBY_DESCRIPTION.include?("darwin")

require "bundler/setup"
require "pidfd"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Only run tests on Linux where pidfd is supported
  config.filter_run_excluding requires_linux: true unless RUBY_PLATFORM.include?("linux")
end
