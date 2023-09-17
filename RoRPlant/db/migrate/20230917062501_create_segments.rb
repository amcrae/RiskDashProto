class CreateSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :segments do |t|
      t.string :uuid
      t.string :shortname
      t.string :segtype
      t.references :segment, null: false, foreign_key: true
      t.string :operational
      t.references :asset, null: false, foreign_key: true

      t.timestamps
    end
  end
end
