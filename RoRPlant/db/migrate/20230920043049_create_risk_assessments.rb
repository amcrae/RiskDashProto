class CreateRiskAssessments < ActiveRecord::Migration[7.0]
  def change
    create_table :risk_assessments do |t|
      t.string :uuid
      t.string     :scope_segment_uuid
      t.references :scope_segment, null: false
      t.string     :output_m_location_uuid
      t.references :output_m_location, null: false
      t.decimal :out_price, precision: 12, scale: 2
      t.string :out_currency
      t.datetime :start_time
      t.string :lookahead
      t.datetime :end_time
      t.string :calc_alg
      t.float :calc_pof
      t.decimal :calc_risk, precision: 12, scale: 2

      t.timestamps
    end
    add_foreign_key :risk_assessments, :m_locations, column: :output_m_location_id, dependent: :delete
    add_foreign_key :risk_assessments, :segments, column: "scope_segment_id", dependent: :delete
  end
end
