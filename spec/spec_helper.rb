require 'rspec'
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])
SimpleCov.start

Coveralls.wear!

require 'bundler/setup'
Bundler.setup

require 'env_setting'

