# frozen_string_literal: true

RSpec.describe Devise::Strategies::PasskeyAuthenticatable do
  let(:user) { User.create!(email: "usertest@example.com", password: "password") }
  let!(:passkey) do
    Passkey.create!(
      user: user,
      external_id: "external-123",
      public_key: "public-key-data",
      name: "My Passkey",
      sign_count: 5
    )
  end
  let(:challenge) { "challenge-xyz-123" }
  let(:credential_response) do
    {
      id: passkey.external_id,
      rawId: passkey.external_id,
      type: "public-key",
      response: {
        authenticatorData: "mock-auth-data",
        clientDataJSON: "mock-client-data",
        signature: "mock-signature"
      }
    }
  end
  let(:env) { Rack::MockRequest.env_for("/users/sign_in", method: "POST") }

  def build_strategy(params: {}, session: {})
    env["rack.session"] = session
    env["action_dispatch.request.parameters"] = params

    s = described_class.new(env)
    allow(s).to receive_messages(params: params, session: session)
    s
  end

  describe "#valid?" do
    it "is not valid without passkey params" do
      s = build_strategy(params: {}, session: {})
      expect(s).not_to be_valid
    end

    it "is not valid without challenge in session" do
      s = build_strategy(params: { user: { passkey_public_key: credential_response.to_json } }, session: {})
      expect(s).not_to be_valid
    end

    it "is valid with both passkey params and challenge" do
      s = build_strategy(params: { user: { passkey_public_key: credential_response.to_json } },
                         session: { authentication_challenge: challenge })
      expect(s).to be_valid
    end
  end

  describe "#authenticate!" do
    let(:mock_credential) { double("webauthn_credential") }

    before do
      allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_credential)
      allow(mock_credential).to receive(:id).and_return(passkey.external_id)
    end

    context "when passkey is not found" do
      before { allow(mock_credential).to receive(:id).and_return("non-existent-id") }

      it "fails authentication" do
        s = build_strategy(
          params: { user: { passkey_public_key: credential_response.to_json } },
          session: { authentication_challenge: challenge }
        )

        s.authenticate!

        expect(s.result).to eq(:failure)
      end

      it "sets the correct failure message" do
        s = build_strategy(
          params: { user: { passkey_public_key: credential_response.to_json } },
          session: { authentication_challenge: challenge }
        )

        s.authenticate!

        expect(s.message).to eq(:passkey_not_found)
      end

      it "clears session" do
        session_data = { authentication_challenge: challenge }
        s = build_strategy(params: { user: { passkey_public_key: credential_response.to_json } }, session: session_data)

        s.authenticate!

        expect(session_data[:authentication_challenge]).to be_nil
      end
    end

    context "when WebAuthn verification raises WebAuthn::Error" do
      before do
        allow(mock_credential).to receive(:verify).and_raise(WebAuthn::Error.new("Verification failed"))
        allow(mock_credential).to receive(:sign_count).and_return(6)
      end

      it "fails authentication" do
        s = build_strategy(
          params: { user: { passkey_public_key: credential_response.to_json } },
          session: { authentication_challenge: challenge }
        )

        s.authenticate!

        expect(s.result).to eq(:failure)
      end

      it "sets the correct failure message" do
        s = build_strategy(
          params: { user: { passkey_public_key: credential_response.to_json } },
          session: { authentication_challenge: challenge }
        )

        s.authenticate!

        expect(s.message).to eq(:passkey_verification_failed)
      end

      it "clears session" do
        session_data = { authentication_challenge: challenge }
        s = build_strategy(params: { user: { passkey_public_key: credential_response.to_json } },
                           session: session_data)

        s.authenticate!

        expect(session_data[:authentication_challenge]).to be_nil
      end
    end

    context "when verification succeeds" do
      let(:new_sign_count) { 10 }

      before do
        allow(mock_credential).to receive_messages(verify: true, sign_count: new_sign_count)
      end

      it "verifies with expected options" do
        s = build_strategy(params: { user: { passkey_public_key: credential_response.to_json } },
                           session: { authentication_challenge: challenge })

        s.authenticate!

        expect(mock_credential).to have_received(:verify).with(
          challenge,
          public_key: passkey.public_key,
          sign_count: passkey.sign_count,
          user_verification: true
        )
      end

      it "clears the challenge from session" do
        session_data = { authentication_challenge: challenge }
        s = build_strategy(
          params: { user: { passkey_public_key: credential_response.to_json } },
          session: session_data
        )

        s.authenticate!

        expect(session_data[:authentication_challenge]).to be_nil
      end

      it "updates the passkey sign count" do
        s = build_strategy(
          params: { user: { passkey_public_key: credential_response.to_json } },
          session: { authentication_challenge: challenge }
        )

        expect do
          s.authenticate!
        end.to change { passkey.reload.sign_count }.to(new_sign_count)
      end
    end
  end
end
