class CreateSegmentConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :segment_connections do |t|
      t.string :uuid
      t.string :shortname
      t.string :segtype
      t.integer :from_segment
      t.integer :to_segment

      t.timestamps
    end
  end
end
