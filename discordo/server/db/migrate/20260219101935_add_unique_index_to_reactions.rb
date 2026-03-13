class AddUniqueIndexToReactions < ActiveRecord::Migration[8.0]
  def change
    add_index :reactions, [:message_id, :user_id, :emoji], unique: true, name: 'index_reactions_on_unique_combination'
  end
end
