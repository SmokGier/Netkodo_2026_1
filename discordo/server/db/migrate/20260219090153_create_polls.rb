class CreatePolls < ActiveRecord::Migration[8.0]
  def change
    create_table :polls do |t|
      t.string :question
      t.text :options
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end
  end
end
