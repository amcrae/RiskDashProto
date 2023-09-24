class AddCapacityToSegments < ActiveRecord::Migration[7.0]
  def change
    add_column :segments, :cur_performance, :float
    add_column :segments, :control_theory, :string
  end
end
