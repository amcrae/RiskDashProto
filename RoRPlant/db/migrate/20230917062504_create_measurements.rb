class CreateMeasurements < ActiveRecord::Migration[7.0]
  def change
    create_table :measurements do |t|
      t.string :uuid
      t.references :mlocation, null: false, foreign_key: true
      t.datetime :timestamp
      t.string :qtype
      t.decimal :v, precision: 16, scale: 6
      t.string :uom

      t.timestamps
    end
  end
end
