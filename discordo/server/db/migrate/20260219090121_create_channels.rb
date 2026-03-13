class CreateChannels < ActiveRecord::Migration[8.0]
  def change
    create_table :channels do |t|
      t.string :name
      t.references :chat_server, null: false, foreign_key: true
      t.integer :position
      t.string :category

      t.timestamps
    end
  end
end
