# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      protected

      def devise_passkeys(_mapping, controllers)
        resources :passkeys, only: %i[new create destroy], controller: controllers[:passkeys]
      end
    end
  end
end
