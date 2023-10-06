class AddRisksToAssets < ActiveRecord::Migration[7.0]
  def change
    add_column :assets, :repaircost, :decimal, precision: 12, scale: 2
    add_column :assets, :repairdelay_sec, :float
    add_column :assets, :decay_factor, :float
  end
end
