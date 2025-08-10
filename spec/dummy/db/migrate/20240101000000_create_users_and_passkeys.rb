# frozen_string_literal: true

class CreateUsersAndPasskeys < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :webauthn_id
      t.timestamps null: false
    end
    add_index :users, :email, unique: true
    add_index :users, :webauthn_id, unique: true

    create_table :passkeys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :name, null: false
      t.integer :sign_count, null: false, default: 0
      t.timestamps null: false
    end
    add_index :passkeys, :external_id, unique: true
  end
end
