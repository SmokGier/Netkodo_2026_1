class AddEncryptionKeyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :encryption_key, :string
  end
end
