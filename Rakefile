require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# RuboCop lives in a separate bundle (gemfiles/rubocop.gemfile) so it is not
# required for the test matrix. Only wire up the task when it is available.
begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  task default: %i[spec rubocop]
rescue LoadError
  task default: %i[spec]
end
