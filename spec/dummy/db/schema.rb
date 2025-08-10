# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 20_240_101_000_000) do
  create_table :users, force: true do |t|
    t.string :email, null: false, default: ""
    t.string :encrypted_password, null: false, default: ""
    t.string :webauthn_id
    t.timestamps null: false
  end
  add_index :users, :email, unique: true
  add_index :users, :webauthn_id, unique: true

  create_table :passkeys, force: true do |t|
    t.references :user, null: false
    t.string :external_id, null: false
    t.string :public_key, null: false
    t.string :name, null: false
    t.integer :sign_count, null: false, default: 0
    t.timestamps null: false
  end
  add_index :passkeys, :external_id, unique: true
end
