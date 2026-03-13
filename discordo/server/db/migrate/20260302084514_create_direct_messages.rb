class CreateDirectMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :direct_messages do |t|
      t.integer :sender_id
      t.integer :recipient_id
      t.text :content
      t.boolean :encrypted

      t.timestamps
    end
  end
end
