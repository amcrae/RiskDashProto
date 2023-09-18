class DataForPumpingAssets < ActiveRecord::Migration[7.0]
  def change
    # Assumes the migration which add the design structure (segments) has been done, so UUIDs can be referenced.
    
    m1 = Segment.find_by(uuid:"1-2dfe-2");
    m1a = Asset.new(uuid:"1-2dfe-201", shortname:"1stMotor", asset_type:"MOTOR", readiness:"SERVICEABLE", pof:0.20);
    m1a.save()
    m1.asset_id = m1a.id
    m1.save()

    m2 = Segment.find_by(uuid:"1-2f33-2");
    m2a = Asset.new(uuid:"1-2f33-202", shortname:"Motor#2", asset_type:"MOTOR", readiness:"SERVICEABLE", pof:0.25);
    m2a.save()
    m2.asset_id = m2a.id
    m2.save()
    
  end
end
