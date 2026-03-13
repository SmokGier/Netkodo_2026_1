class ChangeRoleTypeInUsers < ActiveRecord::Migration[8.0]
  def change
    # Usuń starą kolumnę INTEGER
    remove_column :users, :role, :integer
    
    # Dodaj nową kolumnę string z domyślną wartością 'user'
    add_column :users, :role, :string, default: 'user'
  end
end
