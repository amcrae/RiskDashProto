class DataForPumpSubsystem < ActiveRecord::Migration[7.0]
  def change
    s = Segment.new(shortname:'Plant', segtype:'LOGICAL', operational:'RUNNING');
    s.save()
    
    in1 = Segment.new(parent_id:s.id, shortname:'Inlet', segtype:'PIPE', operational:'RUNNING');
    in1.save();
    out1 = Segment.new(parent_id:s.id, shortname:'Outlet', segtype:'PIPE', operational:'RUNNING');
    out1.save();
    
    ss1 = Segment.new(parent_id:s.id, shortname:'ss1', segtype:'LOGICAL', operational:'RUNNING');
    ss1.save()
    m1 = Segment.new(parent_id:ss1.id, shortname:'M1', segtype:'MOTOR', operational:'RUNNING');
    m1.save()
    p1 = Segment.new(parent_id:ss1.id, shortname:'P1', segtype:'PUMP', operational:'RUNNING');
    p1.save()
    
    ss2 = Segment.new(parent_id:s.id, shortname:'ss2', segtype:'LOGICAL', operational:'RUNNING');
    ss2.save()
    m2 = Segment.new(parent_id:ss2.id, shortname:'M2', segtype:'MOTOR', operational:'RUNNING');
    m2.save()
    p2 = Segment.new(parent_id:ss2.id, shortname:'P1', segtype:'PUMP', operational:'RUNNING');
    p2.save()

    SegmentConnection.new(from_segment:m1.id, to_segment:p1.id, shortname:'Driveshaft', segtype:'SHAFT').save()
    SegmentConnection.new(from_segment:m2.id, to_segment:p2.id, shortname:'Driveshaft', segtype:'SHAFT').save()
    
    SegmentConnection.new(from_segment:in1.id, to_segment:p1.id, shortname:'in', segtype:'PIPE').save()
    SegmentConnection.new(from_segment:p1.id, to_segment:out1.id, shortname:'out', segtype:'PIPE').save()
    
    SegmentConnection.new(from_segment:in1.id, to_segment:p2.id, shortname:'in', segtype:'PIPE').save()
    SegmentConnection.new(from_segment:p2.id, to_segment:out1.id, shortname:'out', segtype:'PIPE').save()
    
  end
end
