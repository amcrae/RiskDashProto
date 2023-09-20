class FixConnectionFks < ActiveRecord::Migration[7.0]
  def change
  	rename_column(:segment_connections, :from_segment, 'from_segment_id')
  	change_column_null(:segment_connections, :from_segment_id, false)
  	rename_column(:segment_connections, :to_segment, 'to_segment_id')
  	change_column_null(:segment_connections, :to_segment_id, false)
  	add_foreign_key(:segment_connections, :segments, column: :from_segment_id, dependent: :delete)
  	add_foreign_key(:segment_connections, :segments, column: :to_segment_id, dependent: :delete)
  	add_index(:segment_connections, :from_segment_id)
  	add_index(:segment_connections, :to_segment_id)
  end
end
