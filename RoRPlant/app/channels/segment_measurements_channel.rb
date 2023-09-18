require 'action_cable'

class SegmentMeasurementsChannel < ApplicationCable::Channel

  def subscribed
    # stream_from "some_channel"
    seg_uuid = params[:segment_uuid]
    stream_from SegmentMeasurementsChannel.measurements_channel_for_subsystem(seg_uuid)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
  
  def SegmentMeasurementsChannel.measurements_channel_for_subsystem(segid)
	"measurements_#{segid}/"  
  end
  
  def SegmentMeasurementsChannel.send_measurement(measurement)
    ancestors = MLocation.get_uuids_to_root(measurement.mlocation_id);
    ancestors.each do | a_uuid |
  	ActionCable.server.broadcast(
  		SegmentMeasurementsChannel.measurements_channel_for_subsystem(a_uuid),
  		measurement
  	)  
    end
  end
  
end
