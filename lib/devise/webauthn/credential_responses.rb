# frozen_string_literal: true

module Devise
  module Webauthn
    module CredentialResponses
      private

      def respond_with_notice(message, location:, status:)
        set_flash_message! :notice, message

        if is_navigational_format?
          redirect_to location
        else
          head status
        end
      end

      def respond_with_alert(message, location:)
        set_flash_message! :alert, message, scope: :"devise.failure"

        if is_navigational_format?
          redirect_to location
        else
          # Rack 2 has no :unprocessable_content and Rack 3.1 deprecates :unprocessable_entity.
          render json: { error: find_message(message, scope: :"devise.failure") }, status: 422 # rubocop:disable Rails/HttpStatus
        end
      end
    end
  end
end
