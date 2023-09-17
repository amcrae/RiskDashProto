class FixSegmentFks < ActiveRecord::Migration[7.0]
  def change
  	remove_index(:segments, name:'index_segments_on_segment_id')
  	remove_foreign_key(:segments, to_table:'segments')
  	rename_column(:segments, :segment_id, 'parent_id')
  	change_column_null(:segments, :parent_id, true)
  	change_column_null(:segments, :asset_id, true)
  	add_foreign_key(:segments, :segments, column: :parent_id, dependent: :delete)
  	add_index(:segments, :parent_id)
  end
end
