# frozen_string_literal: true

appraise "rails-edge" do
  gem "rails", github: "rails/rails", branch: "main"
end

appraise "rails-8_1" do
  gem "rails", "~> 8.1"
end

appraise "rails-8_0" do
  gem "rails", "~> 8.0"
end

appraise "rails-7_2" do
  gem "rails", "~> 7.2"
end

appraise "rails-7_1" do
  gem "rails", "~> 7.1"

  gem "capybara", "~> 3.39"
  gem "importmap-rails", "~> 2.0"
  gem "pry-byebug", "~> 3.10"
  gem "psych", "~> 4.0"
  gem "rack", "~> 2.2"
  gem "rspec-rails", "~> 7.1"
  gem "sqlite3", "~> 1.7"
end
