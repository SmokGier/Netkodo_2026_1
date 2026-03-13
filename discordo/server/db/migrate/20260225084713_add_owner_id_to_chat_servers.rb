class AddOwnerIdToChatServers < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_servers, :owner_id, :integer
  end
end
