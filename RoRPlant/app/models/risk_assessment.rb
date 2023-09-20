class RiskAssessment < ApplicationRecord
  belongs_to :scope_segment, class_name:"Segment", foreign_key:'scope_segment_id', required:false
  belongs_to :output_m_location, class_name:"MLocation", foreign_key:'output_m_location_id', required:false
end
