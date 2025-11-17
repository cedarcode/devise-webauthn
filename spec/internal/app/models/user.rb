class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :passkey_authenticatable,
         :recoverable, :rememberable, :validatable

  # Override this association in order to use `resource_id`
  # as the foreign key in WebauthnCredential.
  has_many :passkeys, dependent: :destroy, class_name: "WebauthnCredential", as: :resource

  # Override this method in order to use `resource_id`
  # as the foreign key in WebauthnCredential.
  def self.find_for_passkey_authentication(passkey)
    passkey.resource if passkey && passkey.resource_type == name
  end
end
