class CreateMLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :m_locations do |t|
      t.string :uuid
      t.references :segment, null: false, foreign_key: true
      t.string :shortname

      t.timestamps
    end
  end
end
