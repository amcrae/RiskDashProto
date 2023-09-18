class MLocation < ApplicationRecord
  belongs_to :segment
  
  def MLocation.get_uuids_to_root(mloc_id)
    answer = [];
    mloc = MLocation.find(mloc_id);
    parent_segid = mloc.segment_id;
    while parent_segid != nil
      s = Segment.find(parent_segid);
      answer.push(s.uuid);
      parent_segid = s.parent_id;
    end
    return answer
  end
  
end
