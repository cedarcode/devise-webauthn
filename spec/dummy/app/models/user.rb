# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :passkey_authenticatable, :registerable
end
