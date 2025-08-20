class CreatePasskeys < ActiveRecord::Migration[8.0]
  def change
    create_table :passkeys do |t|
      t.string :external_id
      t.string :name
      t.text :public_key
      t.integer :sign_count, limit: 8
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :passkeys, :external_id, unique: true
  end
end
