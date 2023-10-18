class AddRoleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :role_name, :string
    add_column :users, :full_name, :string    # Added opportunistically
  end
  
end
