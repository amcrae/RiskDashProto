class AddAuthTypeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :auth_type, :string, null: false, default: "LOCAL"
  end
end
