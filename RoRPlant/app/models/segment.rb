class Segment < ApplicationRecord

  belongs_to :asset, optional:true
  
  attr_accessor :level 
  
  def level=(l)
    @level = l
  end
  
  def level()
    @level
  end

  @path = nil
  attr_accessor :path

  VALID_OPERATIONAL_STATUSES = ['RUNNING', 'OFFLINE']
  
  # TODO: change to a FK into new table
  VALID_SEGMENT_TYPES = ['LOGICAL', 'PIPE', 'SHAFT', 'MOTOR', 'PUMP', 'FLANGE']
  
  validates :shortname, presence:true
  validates :operational, inclusion: { in: VALID_OPERATIONAL_STATUSES }
  validates :segtype, inclusion: { in: VALID_SEGMENT_TYPES }
  
end
