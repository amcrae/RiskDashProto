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
    latest = Measurement.maximum("created_at");
    while @keep_running
  	nothing_new = true;
  	mlist = []
  	begin
  	   mlist = Measurement.where("created_at > ? ", latest );
  	   puts "#(new measurements) = ", mlist.length;
  	   if mlist.length > 0 then
  	     nothing_new = false;
  	   else
  	     sleep(1.0);
  	     # puts "#{Time.now()} DataStreamer tick";
  	   end
  	end while nothing_new;
  	SegmentMeasurementsChannel.send_measurements(mlist);
  	for m in mlist
  	  if m.created_at > latest then
  	    latest = m.created_at
  	  end
  	end
    end
  end
  
end
