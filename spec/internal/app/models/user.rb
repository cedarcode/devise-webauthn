class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :passkey_authenticatable,
         :recoverable, :rememberable, :validatable, :webauthn_two_factor_authenticatable
end
