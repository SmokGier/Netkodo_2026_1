class CreatePollVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :poll_votes do |t|
      t.references :poll, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :option_index

      t.timestamps
    end
  end
end
