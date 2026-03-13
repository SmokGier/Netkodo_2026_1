class AddTypingIndicatorToChatServers < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_servers, :typing_users, :text
  end
end
