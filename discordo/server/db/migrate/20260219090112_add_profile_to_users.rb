class AddProfileToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :avatar_url, :string
    add_column :users, :status, :string
    add_column :users, :rich_presence, :string
    add_column :users, :bio, :text
  end
end
