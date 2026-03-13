class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.text :content
      t.string :username
      t.string :room

      t.timestamps
    end
  end
end
