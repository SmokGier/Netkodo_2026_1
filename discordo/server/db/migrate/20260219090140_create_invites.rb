class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites do |t|
      t.string :code
      t.references :chat_server, null: false, foreign_key: true
      t.datetime :expires_at
      t.integer :uses_left
      t.integer :creator_id

      t.timestamps
    end
  end
end
