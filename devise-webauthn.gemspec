# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "devise/webauthn/version"

Gem::Specification.new do |spec|
  spec.name          = "devise-webauthn"
  spec.version       = Devise::Webauthn::VERSION
  spec.authors       = ["Cedarcode"]
  spec.email         = ["webauthn@cedarcode.com"]

  spec.summary       = "Devise extension to support WebAuthn."
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 3.1"

  spec.add_development_dependency "importmap-rails"
  spec.add_development_dependency "propshaft", "~> 1.2"
  spec.add_development_dependency "puma", "~> 6.6"
  spec.add_development_dependency "rails", "~> 8.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.79"
  spec.add_development_dependency "rubocop-rails", "~> 2.32"
  spec.add_development_dependency "rubocop-rspec", "~> 3.6"
  spec.add_development_dependency "sqlite3", "~> 2.7"
  spec.add_development_dependency "stimulus-rails"

  spec.add_dependency "devise", "~> 4.9"
  spec.add_dependency "webauthn", "~> 3.0"
end
