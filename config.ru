# frozen_string_literal: true

require "rubygems"
require "bundler"

Bundler.require :default, :development

Combustion.initialize! :all do
  config.load_defaults Rails.version.to_f
end
run Combustion::Application
