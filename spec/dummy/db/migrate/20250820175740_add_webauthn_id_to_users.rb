class AddWebauthnIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :webauthn_id, :string
    add_index :users, :webauthn_id, unique: true
  end
end
