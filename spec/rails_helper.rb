# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "rspec/rails"

ActiveRecord::Schema.verbose = false

load Rails.root.join("db/schema.rb")
