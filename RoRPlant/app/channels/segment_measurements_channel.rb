require 'action_cable'

class SegmentMeasurementsChannel < ApplicationCable::Channel

  def subscribed
    # stream_from "some_channel"
    seg_uuid = params[:segment_uuid];
    stream_from SegmentMeasurementsChannel.measurements_channel_for_subsystem(seg_uuid);
    DataStreamerJob.new().run_in_new_thread();
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
  
  def SegmentMeasurementsChannel.measurements_channel_for_subsystem(seg_uuid)
  	# channel needs to be specific to instance, not just design name.
	"measurements_#{seg_uuid}/"
  end
  
  def SegmentMeasurementsChannel.send_measurement(measurement)
    # for compatibility this now sends a list consisting of a single measurement.
    ancestors = MLocation.get_uuids_to_root(measurement.m_location_id);
    ancestors.each do | a_uuid |
  	ActionCable.server.broadcast(
  		SegmentMeasurementsChannel.measurements_channel_for_subsystem(a_uuid),
  		[measurement]
  	)  
    end
  end

  def SegmentMeasurementsChannel.send_measurements(measurement_list)
    # Any messages which share the same delivery scope should be sent together for efficiency.
    # Therefore partition all given measurements into batches of same delivery scope based on system hierarchy.
    notify_scopes = {}
    for measurement in measurement_list do
      ancestors = MLocation.get_uuids_to_root(measurement.m_location_id);
      msg_scope = []
      ancestors.each do | a_uuid |
        ch_name = SegmentMeasurementsChannel.measurements_channel_for_subsystem(a_uuid);
        msg_scope.push(ch_name)
      end
      if !(notify_scopes.has_key?(msg_scope)) then
	      notify_scopes[msg_scope] = [];
      end
      notify_scopes[msg_scope].push(measurement);
    end
    # Each scope has its own batch of measurements.
    # puts "notify_scopes", notify_scopes;
    for scope,batch in notify_scopes
    	# print(scope, '<---', batch, "\n");
        for chan in scope
  	  ActionCable.server.broadcast(chan, batch);
  	end
     end
    
  end
  
end
