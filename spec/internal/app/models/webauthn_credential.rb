class WebauthnCredential < ApplicationRecord
  belongs_to :user
  validates :external_id, :public_key, :name, :sign_count, presence: true
  validates :external_id, uniqueness: true

  enum :authentication_factor, { first_factor: 0, second_factor: 1 }

  scope :passkey, -> { first_factor }
end
