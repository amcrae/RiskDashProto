class SegmentConnection < ApplicationRecord
  belongs_to :from_seg, class_name:"Segment", foreign_key:'from_segment_id'
  belongs_to :to_seg,  class_name:"Segment", foreign_key:'to_segment_id'
end

