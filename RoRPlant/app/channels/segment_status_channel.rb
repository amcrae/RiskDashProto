class SegmentStatusChannel < ApplicationCable::Channel

  def SegmentStatusChannel.channel_for_subsystem(seg_uuid)
	"statuses_#{seg_uuid}/"  
  end

  def subscribed
    seg_uuid = params[:segment_uuid];
    puts "Subscriber for statuses of", seg_uuid 
    stream_from SegmentStatusChannel.channel_for_subsystem(seg_uuid);
    DataStreamerJob.new().run_in_new_thread();    
  end


  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end


  def SegmentStatusChannel.send_statuses(seg_statuses_list)
    # TODO: make this common scoping logic more DRY (with send_measurements) 
    # Any messages which share the same delivery scope should be sent together for efficiency.
    # Therefore partition all given messages into batches of same delivery scope based on system hierarchy.
    notify_scopes = {}
    for seg_status in seg_statuses_list do
      ancestors = Segment.get_uuids_to_root(seg_status.id);
      msg_scope = []
      ancestors.each do | a_uuid |
        ch_name = SegmentStatusChannel.channel_for_subsystem(a_uuid);
        msg_scope.push(ch_name)
      end
      if !(notify_scopes.has_key?(msg_scope)) then
	      notify_scopes[msg_scope] = [];
      end
      notify_scopes[msg_scope].push(seg_status);
    end
    # Each scope has its own batch of segment statuses.
    # puts "notify_scopes", notify_scopes;
    for scope,batch in notify_scopes
        # print(scope, '<---', batch, "\n");
        for chan in scope
            ActionCable.server.broadcast(chan, batch);
        end
    end
    
  end

end
