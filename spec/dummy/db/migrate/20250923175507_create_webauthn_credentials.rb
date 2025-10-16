class CreateWebauthnCredentials < ActiveRecord::Migration[7.2]
  def change
    create_table :webauthn_credentials do |t|
      t.string :external_id
      t.string :name
      t.text :public_key
      t.integer :sign_count, limit: 8
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :webauthn_credentials, :external_id, unique: true
  end
end
