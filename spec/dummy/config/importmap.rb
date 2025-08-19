# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @8.0.201
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
