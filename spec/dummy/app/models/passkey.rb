# frozen_string_literal: true

class Passkey < ApplicationRecord
  belongs_to :user

  validates :external_id, :public_key, :name, :sign_count, presence: true
  validates :external_id, uniqueness: true
end
