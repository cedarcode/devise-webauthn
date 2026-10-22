# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new("spec:api") do |task|
  task.rspec_opts = "--options .rspec-api"
  task.pattern = "spec/api/**/*_spec.rb"
end

task default: %i[spec spec:api]
