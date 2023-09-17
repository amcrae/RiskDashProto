class CreateAssets < ActiveRecord::Migration[7.0]
  def change
    create_table :assets do |t|
      t.string :uuid
      t.string :shortname
      t.string :asset_type
      t.string :readiness
      t.float :pof

      t.timestamps
    end
  end
end
