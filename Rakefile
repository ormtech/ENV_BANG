require "bundler/gem_tasks"
require "rspec/core/rake_task"

namespace 'dotenv' do
  Bundler::GemHelper.install_tasks :name => 'env_setting'
end

desc 'Run all tests'
RSpec::Core::RakeTask.new(:spec) do |s|
  s.rspec_opts = '-f d -c'
  s.pattern = 'spec/**/*_spec.rb'
end
task :default => :spec
