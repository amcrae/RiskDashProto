class DataForPumpSubsystem < ActiveRecord::Migration[7.0]
  def change
    s = Segment.new(shortname:'Plant',uuid:"1-2b01-0", segtype:'LOGICAL', operational:'RUNNING');
    s.save()
    
    in1 = Segment.new(parent_id:s.id, uuid:"1-2b01-1", shortname:'Inlet', segtype:'PIPE', operational:'RUNNING');
    in1.save();
    out1 = Segment.new(parent_id:s.id, uuid:"1-2b01-2",shortname:'Outlet', segtype:'PIPE', operational:'RUNNING');
    out1.save();
    
    ss1 = Segment.new(parent_id:s.id, uuid:"1-2dfe-1", shortname:'ss1', segtype:'LOGICAL', operational:'RUNNING');
    ss1.save()
    m1 = Segment.new(parent_id:ss1.id, uuid:"1-2dfe-2", shortname:'M1', segtype:'MOTOR', operational:'RUNNING');
    m1.save()
    p1 = Segment.new(parent_id:ss1.id, uuid:"1-2dfe-3", shortname:'P1', segtype:'PUMP', operational:'RUNNING');
    p1.save()
    
    ss2 = Segment.new(parent_id:s.id, uuid:"1-2f33-1", shortname:'ss2', segtype:'LOGICAL', operational:'RUNNING');
    ss2.save()
    m2 = Segment.new(parent_id:ss2.id, uuid:"1-2f33-2", shortname:'M2', segtype:'MOTOR', operational:'RUNNING');
    m2.save()
    p2 = Segment.new(parent_id:ss2.id, uuid:"1-2f33-3", shortname:'P1', segtype:'PUMP', operational:'RUNNING');
    p2.save()

    SegmentConnection.new(from_segment:m1.id, to_segment:p1.id, shortname:'Driveshaft', segtype:'SHAFT').save()
    SegmentConnection.new(from_segment:m2.id, to_segment:p2.id, shortname:'Driveshaft', segtype:'SHAFT').save()
    
    SegmentConnection.new(from_segment:in1.id, to_segment:p1.id, shortname:'in', segtype:'PIPE').save()
    SegmentConnection.new(from_segment:p1.id, to_segment:out1.id, shortname:'out', segtype:'PIPE').save()
    
    SegmentConnection.new(from_segment:in1.id, to_segment:p2.id, shortname:'in', segtype:'PIPE').save()
    SegmentConnection.new(from_segment:p2.id, to_segment:out1.id, shortname:'out', segtype:'PIPE').save()
    
    MLocation.new(uuid:"1-2b01-1-1", segment_id:in1.id, shortname:"InFlowmeter").save();
        
    MLocation.new(uuid:"1-2dfe-2-1", segment_id:m1.id, shortname:"DC_In").save();
    MLocation.new(uuid:"1-2dfe-3-1", segment_id:p1.id, shortname:"Outlet").save();
    MLocation.new(uuid:"1-2f33-2-1", segment_id:m2.id, shortname:"DC_In").save();
    MLocation.new(uuid:"1-2f33-3-1", segment_id:p2.id, shortname:"Outlet").save();            
    
    MLocation.new(uuid:"1-2b01-2-1", segment_id:out1.id, shortname:"OutFlowmeter").save();
        
  end
end