#frozen_string_literal: true

# puts "Start loading Segment", caller, ""

class Segment < ApplicationRecord
  belongs_to :parent, class_name:"Segment", foreign_key:'parent_id', optional:true

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
  # As these should come from an external source/table that could grow in size, the possibility of filling the ruby Symbol table arises.
  # The pragma at top will ensure these tokens are frozen, and a .freeze() would be done on data imported from database or file.
  VALID_SEGMENT_TYPES = ['LOGICAL', 'PORT', 'PIPE', 'SHAFT', 'MOTOR', 'PUMP', 'FLANGE', 'VALVE', 'CABLE', 'PLUG', 'SOCKET', 'SWITCH']
  
  # TODO: move to new table.
  SEGMENT_TYPE_COEFFS = {
    'LOGICAL' => [],
    'PORT' => [],
    'PIPE'  => [],
    'SHAFT' => [],
    'MOTOR' => ['current --> angular velocity', 'efficiency'], # simplistic, but the goal is to learn RoR not motor theory.
    'PUMP' => ['angular velocity --> volumetric flow','efficiency'], 
    'FLANGE' => [], 
    'VALVE' => [], 
    'CABLE' => [], 
    'PLUG' => [], 
    'SOCKET' => [], 
    'SWITCH' => []
  }
  
  validates :shortname, presence:true
  validates :operational, inclusion: { in: VALID_OPERATIONAL_STATUSES }
  validates :segtype, inclusion: { in: VALID_SEGMENT_TYPES }
  
  
  def Segment.get_uuids_to_root(seg_id)
    answer = [];
    parent_segid = seg_id;
    while parent_segid != nil
      s = Segment.find(parent_segid);
      answer.push(s.uuid);
      parent_segid = s.parent_id;
    end
    return answer
  end
    
end
