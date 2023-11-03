# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

    s = Segment.new(shortname:'Plant',uuid:"1-2b01-0", segtype:'LOGICAL', operational:'RUNNING');
    s.save()
    
    in1 = Segment.new(parent_id:s.id, uuid:"1-2b01-1", shortname:'Inlet', segtype:'PIPE', operational:'RUNNING');
    in1.save();
    out1 = Segment.new(parent_id:s.id, uuid:"1-2b01-2",shortname:'Outlet', segtype:'PIPE', operational:'RUNNING');
    out1.save();
    
    fog =  Segment.new(parent_id:s.id, uuid:"1-2b01-9", shortname:'FailoverGroup', segtype:'LOGICAL', operational:'RUNNING', control_theory:"{'REQUIRE_M_RUNNING':1}");
    fog.save()
    
    ss1 = Segment.new(parent_id:fog.id, uuid:"1-2dfe-0", shortname:'ss1', segtype:'LOGICAL', operational:'RUNNING');
    ss1.save()
    m1 = Segment.new(parent_id:ss1.id, uuid:"1-2dfe-2", shortname:'M1', segtype:'MOTOR', operational:'RUNNING');
    m1.save()
    p1 = Segment.new(parent_id:ss1.id, uuid:"1-2dfe-3", shortname:'P1', segtype:'PUMP',  operational:'RUNNING');
    p1.save()
    
    ss2 = Segment.new(parent_id:fog.id, uuid:"1-2f33-0", shortname:'ss2', segtype:'LOGICAL', operational:'RUNNING');
    ss2.save()
    m2 = Segment.new(parent_id:ss2.id, uuid:"1-2f33-2", shortname:'M2', segtype:'MOTOR', operational:'RUNNING');
    m2.save()
    p2 = Segment.new(parent_id:ss2.id, uuid:"1-2f33-3", shortname:'P2', segtype:'PUMP', operational:'RUNNING');
    p2.save()

    SegmentConnection.new(uuid:'1-1-1', from_segment_id:m1.id, to_segment_id:p1.id, shortname:'Driveshaft', segtype:'SHAFT').save()
    SegmentConnection.new(uuid:'1-2-1', from_segment_id:m2.id, to_segment_id:p2.id, shortname:'Driveshaft', segtype:'SHAFT').save()
    
    SegmentConnection.new(uuid:'1-1-0', from_segment_id:in1.id, to_segment_id:p1.id, shortname:'in', segtype:'PIPE').save()
    SegmentConnection.new(uuid:'1-1-9', from_segment_id:p1.id, to_segment_id:out1.id, shortname:'out', segtype:'PIPE').save()
    
    SegmentConnection.new(uuid:'1-2-0', from_segment_id:in1.id, to_segment_id:p2.id, shortname:'in', segtype:'PIPE').save()
    SegmentConnection.new(uuid:'1-2-9', from_segment_id:p2.id, to_segment_id:out1.id, shortname:'out', segtype:'PIPE').save()
    
    MLocation.new(uuid:"1-2b01-1-1", segment_id:in1.id, shortname:"InFlowmeter", qtype:'volumetric flow').save();
    
    MLocation.new(uuid:"1-2dfe-2-1", segment_id:m1.id, shortname:"DC_In",  qtype:'current').save();
    MLocation.new(uuid:"1-2dfe-3-1", segment_id:p1.id, shortname:"Outlet", qtype:'volumetric flow').save();
    MLocation.new(uuid:"1-2f33-2-1", segment_id:m2.id, shortname:"DC_In",  qtype:'current').save();
    MLocation.new(uuid:"1-2f33-3-1", segment_id:p2.id, shortname:"Outlet", qtype:'volumetric flow').save();
    
    MLocation.new(uuid:"1-2b01-2-1", segment_id:out1.id, shortname:"OutFlowmeter", qtype:'volumetric flow').save();
    

    # Assumes the migration which add the design structure (segments) has been done, so UUIDs can be referenced.
    
    m1 = Segment.find_by(uuid:"1-2dfe-2");
    m1a = Asset.new(
        uuid:"1-2dfe-201", shortname:"1stMotor", asset_type:"MOTOR", pof:0.20, max_capacity:31.4,
        repaircost: 1000.00, repairdelay_sec: 3600, decay_factor: 0.0001,
        perf_coeffs:'{"current --> angular velocity":3.14, "efficiency":0.85}', readiness:"SERVICEABLE"
    );
    m1a.save();
    m1.asset_id = m1a.id;
    m1.save()

    p1 = Segment.find_by(uuid:"1-2dfe-3");
    p1a = Asset.new(
        uuid:"1-2dfe-3-101", shortname:"Pumpomatic1", asset_type:"PUMP", pof:0.001, max_capacity:10.0,
        repaircost: 1000.00, repairdelay_sec: 3600, decay_factor: 0.0001,
        perf_coeffs:'{"angular velocity --> volumetric flow":2.0, "efficiency":0.92 }', readiness:"SERVICEABLE"
    );
    p1a.save();
    p1.asset_id = p1a.id;
    p1.save()

    m2 = Segment.find_by(uuid:"1-2f33-2");
    m2a = Asset.new(uuid:"1-2f33-202", shortname:"Motor#2", asset_type:"MOTOR", pof:0.25, max_capacity:31.4, 
        repaircost: 1000.00, repairdelay_sec: 3600, decay_factor: 0.0001,
        perf_coeffs:'{"current --> angular velocity":3.14, "efficiency":0.85}', readiness:"SERVICEABLE"
    );
    m2a.save();
    m2.asset_id = m2a.id
    m2.save()

    p2 = Segment.find_by(uuid:"1-2f33-3");
    p2a = Asset.new(
        uuid:"1-2f33-3-201", shortname:"ACME_P100", asset_type:"PUMP", pof:0.002, max_capacity:10.0, 
        repaircost: 800.00, repairdelay_sec: 1800, decay_factor: 0.0002,
        perf_coeffs:'{"angular velocity --> volumetric flow":2.0, "efficiency":0.90 }', readiness:"SERVICEABLE"
    );
    p2a.save();
    p2.asset_id = p2a.id;
    p2.save()

    # Permissions model
    RolePermission.new(role_name: "TECHNICIAN", obj_name: "Asset", perm_name: "manage").save();
    RolePermission.new(role_name: "TECHNICIAN", obj_name: "Asset", perm_name: "repair").save();
    RolePermission.new(role_name: "TERRORIST", obj_name: "Asset", perm_name: "sabotage").save();
    
    # Create sample users
    puts "'seeds.rb' users creation..."
    u1 = User.new(
      auth_type: "LOCAL",
      email: "user1@example.com", password: "scoTTY", full_name: "Montgomery Scott", role_name: "TECHNICIAN"
    );
    u1.save()

    u2 = User.new(
      auth_type: "EXTERNAL",
      email: "user2@example.com", password: "abc_123", full_name: "User McTwo", role_name: "TECHNICIAN"
    );
    u2.save()
    
    u3 = User.new(
      auth_type: "LOCAL",
      email: "user3@example.com", password: "3v!l_Inc", full_name: "Terry Wrist", role_name: "TERRORIST"
    );
    u3.save()
