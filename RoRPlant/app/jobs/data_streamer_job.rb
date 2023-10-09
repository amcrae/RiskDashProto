# Not actually intended to run as an ActiveJob.
# It needs to communicate with the web clients and this is quicker to implement as a thread
#  rather than set up a separate client comms channel to a secondary process.
class DataStreamerJob < ApplicationJob
  queue_as :default

  def run_in_new_thread()
    tconf = Rails.application.config;
    if (tconf.streamer_thread != nil and tconf.streamer_thread.alive?) then
    	Rails.logger.warn("Request to start streamer thread rejected as old thread is still alive.")
    else
    	Rails.logger.info("Request to start streamer thread permitted.")
  	@keep_running = true
    	tconf.streamer_thread = Thread.new() {
    	  perform();
    	}
    end
  end




  def perform(*args)
    Rails.logger.info("DataStreamer started!");
    latest_m = Measurement.maximum("created_at") or Time.now();
    latest_s = Segment.maximum("updated_at");
    while @keep_running
        nothing_new = true;
        mlist = []
        begin
            mlist = Measurement.where("created_at > ? ", latest_m );
            # puts "#(new measurements) = ", mlist.length;
            segs = Segment.where("updated_at > ? ", latest_s);
            if mlist.length > 0 or segs.length > 0 then
             nothing_new = false;
            else
             sleep(0.25);
             # puts "#{Time.now()} DataStreamer tick";
            end
      	end while nothing_new;
      	if mlist.length > 0 then SegmentMeasurementsChannel.send_measurements(mlist); end;
      	if segs.length > 0 then SegmentStatusChannel.send_statuses(segs); end;

        # Should keep each channel devoted to a particular message type, much like OIIE ISBM.
        # TODO: Need a whole new ActiveCable Channel for RiskAssessments
        # TODO: stream new risk assessments here too.
      	
      	for m in mlist
      	  if m.created_at > latest_m then
      	    latest_m = m.created_at
      	  end
      	end
      	
      	for s in segs
      	  if s.updated_at > latest_s then
      	    latest_s = s.updated_at
      	  end
      	end
      	    
    end
  end
  
end
