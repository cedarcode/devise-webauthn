# frozen_string_literal: true

# Stands in for devise-jwt: authenticates each request with a Bearer token and never stores the user in the session.
class BearerTokenStrategy < Devise::Strategies::Base
  def self.token_for(resource)
    resource.signed_id(purpose: :api)
  end

  def valid?
    token.present?
  end

  def store?
    false
  end

  def authenticate!
    resource = mapping.to.find_signed(token, purpose: :api)
    resource ? success!(resource) : fail!(:invalid)
  end

  private

  def token
    env["HTTP_AUTHORIZATION"].to_s[/\ABearer (.+)\z/, 1]
  end
end

Warden::Strategies.add(:bearer_token, BearerTokenStrategy)

# With `skip_storage: :per_request`, the app keeps the default `skip_session_storage` and each request sets
# `devise.skip_storage` instead, as an app that also serves cookie sessions on the same scope does.
RSpec.shared_context "with a JSON client without a session" do |skip_storage: :global|
  let(:without_session_env) { skip_storage == :per_request ? { "devise.skip_storage" => true } : {} }

  around do |example|
    original_store = Devise::Webauthn.challenge_store
    original_cache = Devise::Webauthn::ChallengeStores::Cache.cache
    original_skip_session_storage = Account.skip_session_storage

    Devise::Webauthn.challenge_store = :cache
    Devise::Webauthn::ChallengeStores::Cache.cache = ActiveSupport::Cache::MemoryStore.new
    Account.skip_session_storage = %i[http_auth params_auth] if skip_storage == :global
    # After the passkey strategy, where devise-jwt puts `:jwt`.
    Devise.configure_warden!
    strategies = Devise.warden_config.default_strategies(scope: :account)
    strategies.insert(strategies.index(:passkey_authenticatable) + 1, :bearer_token)
    example.run
  ensure
    Devise::Webauthn.challenge_store = original_store
    Devise::Webauthn::ChallengeStores::Cache.cache = original_cache
    Account.skip_session_storage = original_skip_session_storage
    strategies&.delete(:bearer_token)
  end

  # Every request starts a new integration session, so no cookie carries state between requests.
  # `authenticated_as` sends a Bearer token for that request only, as an API client does.
  def without_session_json_post(path, authenticated_as: nil, **params)
    headers = start_request_without_session(authenticated_as)
    post path, params: params, as: :json, env: without_session_env, headers: headers
  end

  def without_session_json_patch(path, authenticated_as: nil)
    headers = start_request_without_session(authenticated_as)
    patch path, as: :json, env: without_session_env, headers: headers
  end

  def without_session_json_delete(path, authenticated_as: nil)
    headers = start_request_without_session(authenticated_as)
    delete path, as: :json, env: without_session_env, headers: headers
  end

  # An app that routes only the JSON actions has no HTML page to redirect to, so its path helpers raise.
  def without_html_pages_routed(*path_methods)
    allow(described_class).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap do |controller|
        path_methods.each do |path_method|
          allow(controller).to receive(path_method).and_raise(NoMethodError, "undefined method '#{path_method}'")
        end
      end
    end
  end

  def start_request_without_session(user)
    reset!
    user ? { "Authorization" => "Bearer #{BearerTokenStrategy.token_for(user)}" } : {}
  end
end

RSpec.shared_examples "a controller that loads under an ActionController::API parent" do
  # RSpec restores the hidden controller by redefining its constant.
  around { |example| silence_warnings { example.run } }

  it "loads under an ActionController::API parent" do
    # Hiding autoloads the real controller, so it must happen before DeviseController is stubbed.
    hide_const(described_class.name)
    stub_const("DeviseController", Class.new(ActionController::API))
    path = Devise::Webauthn::Engine.root.join("app/controllers/#{described_class.name.underscore}.rb")

    expect { load path.to_s }.not_to raise_error
  end
end
