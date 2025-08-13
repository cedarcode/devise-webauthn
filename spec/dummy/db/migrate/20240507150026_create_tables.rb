# frozen_string_literal: true

class CreateTables < ActiveRecord::Migration[7.1]
  def change
    create_table :users, force: true do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :webauthn_id
      t.timestamps null: false
      t.index :webauthn_id, unique: true
      t.index :email, unique: true
    end

    create_table :passkeys, force: true do |t|
      t.references :user, null: false
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :name, null: false
      t.integer :sign_count, null: false, default: 0
      t.timestamps null: false
      t.index :external_id, unique: true
    end
  end
end
