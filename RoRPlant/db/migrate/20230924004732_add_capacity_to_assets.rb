class AddCapacityToAssets < ActiveRecord::Migration[7.0]
  def change
    add_column :assets, :max_capacity, :float
    add_column :assets, :perf_coeffs, :string
  end
end
