# frozen_string_literal: true

RSpec.shared_context "with a JSON client without a session" do
  around do |example|
    original_store = Devise::Webauthn.challenge_store
    original_cache = Devise::Webauthn::ChallengeStores::Cache.cache
    original_skip_session_storage = Account.skip_session_storage

    Devise::Webauthn.challenge_store = :cache
    Devise::Webauthn::ChallengeStores::Cache.cache = ActiveSupport::Cache::MemoryStore.new
    Account.skip_session_storage = %i[http_auth params_auth]
    example.run
  ensure
    Devise::Webauthn.challenge_store = original_store
    Devise::Webauthn::ChallengeStores::Cache.cache = original_cache
    Account.skip_session_storage = original_skip_session_storage
  end

  # Every request starts a new integration session, so no cookie carries state between requests.
  # `authenticated_as` signs in for that request only, like the token an API client sends.
  def without_session_json_post(path, authenticated_as: nil, **params)
    start_request_without_session(authenticated_as)
    post path, params: params, as: :json
  end

  def without_session_json_patch(path, authenticated_as: nil, **params)
    start_request_without_session(authenticated_as)
    patch path, params: params, as: :json
  end

  def without_session_json_delete(path, authenticated_as: nil)
    start_request_without_session(authenticated_as)
    delete path, as: :json
  end

  def start_request_without_session(user)
    reset!
    sign_in user, scope: :account if user
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
