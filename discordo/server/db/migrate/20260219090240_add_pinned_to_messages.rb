class AddPinnedToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :pinned, :boolean
  end
end
