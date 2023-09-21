# require "test_helper"
require_relative '../test_helper'

class SegmentConnectionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def test_save_populated_by_id
    # add a power cable for the motor input
    ss1 = Segment.find_by(uuid:"1-2dfe-0")
    m1 =  Segment.find_by(uuid:"1-2dfe-2")
    wallplug = Segment.new(parent_id:ss1.id, uuid:"1-2dfe-7", shortname:'plug', segtype:'PLUG', operational:'RUNNING')
    puts "Saving wallplug..."
    wallplug.save()
    puts "Saved wallplug"
    c1 = SegmentConnection.new(from_segment_id:wallplug.id, to_segment_id:m1.id, shortname:'power cable', segtype:'CABLE')
    puts c1
    success = c1.save()
    puts c1
    puts "Saved connection cable"
    c1.destroy()
    wallplug.destroy()
    assert success
  end

  def test_save_populated_by_assoc
    # add a power cable for the motor input
    ss1 = Segment.find_by(uuid:"1-2dfe-0")
    m1 =  Segment.find_by(uuid:"1-2dfe-2")
    wallplug = Segment.new(parent:ss1, uuid:"1-2dfe-7", shortname:'plug', segtype:'PLUG', operational:'RUNNING')
    #wallplug.parent = ss1
    puts "Saving wallplug..."
    wallplug.save()
    puts "Saved wallplug"
    assert wallplug.parent_id != nil
    assert wallplug.parent_id == ss1.id
    c1 = SegmentConnection.new(from_seg:wallplug, to_seg:m1, shortname:'power cable', segtype:'CABLE')
    puts c1
    success = c1.save()
    puts c1
    puts "Saved connection cable"
    c1.destroy()
    wallplug.destroy()
    assert success
  end

end
