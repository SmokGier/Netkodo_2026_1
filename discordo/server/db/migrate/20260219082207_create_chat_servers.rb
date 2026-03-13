class CreateChatServers < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_servers do |t|
      t.string :name
      t.string :password_digest

      t.timestamps
    end
  end
end
