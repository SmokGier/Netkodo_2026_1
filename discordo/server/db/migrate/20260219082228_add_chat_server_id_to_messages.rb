class AddChatServerIdToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :chat_server_id, :integer
  end
end
