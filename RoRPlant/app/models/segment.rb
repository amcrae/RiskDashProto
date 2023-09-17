class Segment < ApplicationRecord
  has_one :asset

  VALID_OPERATIONAL_STATUSES = ['RUNNING', 'OFFLINE']
  
  # TODO: change to a FK into new table
  VALID_SEGMENT_TYPES = ['LOGICAL', 'PIPE', 'SHAFT', 'MOTOR', 'PUMP', 'FLANGE']
  
  validates :shortname, presence:true
  validates :operational, inclusion: { in: VALID_OPERATIONAL_STATUSES }
  validates :segtype, inclusion: { in: VALID_SEGMENT_TYPES }
  
end
