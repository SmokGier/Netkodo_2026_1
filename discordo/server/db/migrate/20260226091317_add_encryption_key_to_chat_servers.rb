class AddEncryptionKeyToChatServers < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_servers, :encryption_key, :string
  end
end
