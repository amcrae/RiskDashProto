class CreateRolePermissions < ActiveRecord::Migration[7.0]
  def change
    create_table :role_permissions do |t|
      t.string :role_name, null: false
      t.string :obj_name, null: false
      t.string :perm_name, null: false

      t.timestamps
    end
    add_index :role_permissions, :role_name, unique: false
  end
end
