require "action_cable"

class SynthesiseDataJob < ApplicationJob
  queue_as :default

  # try to ensure only one worker pool runs all synth jobs
  @@singleton_process = nil
  
  attr_accessor :keep_running, :last_value

  # TODO: should be configurable by caller of perform. hardcoded for demo expediency.
  MLOC_DATA_DISTRIBUTIONS = [
    {mloc_uuid:"1-2dfe-2-1", avg_val:15.0, phase: 0.0, template:{qtype:"Current", uom:"A"} },
    # {mloc_uuid:"1-2f33-2-1", avg_val:14.9, phase: 500.0, template:{qtype:"Current", uom:"A"} }
  ]
  
  def SynthesiseDataJob.singleton_process()
  	return @@singleton_process
  end

  def SynthesiseDataJob.singleton_process=(new_proc)
  	@@singleton_process = new_proc
  end
  

  def initialize(*args)
    super(*args)
    @mlocs = {}
    MLOC_DATA_DISTRIBUTIONS.each do |mdist|
      # Rails.logger.debug("Find #{mdist}");
      muuid = mdist[:mloc_uuid];
      mloc = MLocation.find_by(uuid:muuid);
      if mloc == nil then
      	Rails.logger.error("no mloc for #{mdist}");
      end
      # Rails.logger.debug("Found #{mloc}");
      @mlocs[mloc.uuid] = mloc;
    end

  end


  def run_as_queued_job()
    j = SynthesiseDataJob.perform_later();
    puts "perform_later => ", j
  end


  def run_in_thread()
    # Thread.new(4, 15.0) { |segid, loc_name, avg_val|
    #   perform(segid, loc_name, avg_val)
    # }
    Thread.new() {
      perform()
    }
  end

  
  def run_as_new_process()
    SynthesiseDataJob.perform_later();
    puts "singleton_process == #{SynthesiseDataJob.singleton_process()}";
    # TODO: figure out why @@singleton_process is nil after the process was started.
    if SynthesiseDataJob.singleton_process() != nil then
    	puts "SynthesiseDataJob singleton apparently already started.";
    	Rails.logger.warn("SynthesiseDataJob singleton apparently already started.");
    	return
    end
    job = self
    fork do
	# require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))
	require 'delayed/command'
	SynthesiseDataJob.singleton_process = Delayed::Command.new(["run","--exit-on-complete"]);
    	puts "singleton_process == #{SynthesiseDataJob.singleton_process()}";

	# @@singleton_process.daemonize()  # runs delayed_job
	@@singleton_process.run_process("bkg1");
	
	puts "singleton_process == #{SynthesiseDataJob.singleton_process()}";
	puts "******* EXITING run_as_new_process";
	Process.kill 9, Process.pid
    end
  end


  def gen_measurement_for(mdist, simtime_s)
    phasedt = simtime_s + mdist[:phase];
    pt = phasedt/3600;  # perlin phase 
    mloc = @mlocs[mdist[:mloc_uuid]];
    if mloc == nil then raise StandardError.new("nil mloc from hash."); end;
    seg = Segment.find(mloc.segment_id);
    if seg.operational == 'RUNNING' then
      last_value = mdist[:avg_val] + (0.66*@n1d[pt] + 0.34*@n1d[pt*3.2] - 0.5);
    else
      last_value = 0;
    end
    # logger.debug(@last_value);
    mmsg = Measurement.new(
        uuid: Random.uuid(),
	    m_location_id: mloc.id,
	    timestamp: @sim_start_time + simtime_s,
	    qtype: mdist[:template][:qtype],
	    v: last_value,
	    uom: mdist[:template][:uom]
    );
    return mmsg
  end

  SIM_TIME_PER_SECOND = (6*60);  # F2.14
  
  def perform(*args)
    Rails.logger.debug("Init synth with #{args}")
    @keep_running = true
    # @loc_name = args[1]
    # @avg_val = args[2]
    @last_value = nil
    @last_message = nil
    
    @n1d = Perlin::Noise.new(1, {:interval=>3 } )  # 20-minute size features?

    Rails.logger.debug("Started synth")
    simtime_s = 0.0
    @sim_start_time = Time.now();
    
    while self.keep_running and simtime_s<(3600*12) do
    	data_frame = []
    	MLOC_DATA_DISTRIBUTIONS.each do |mdist|
    	  mmsg = gen_measurement_for(mdist, simtime_s);
    	  data_frame.push(mmsg);
    	end
    	@last_message = data_frame;
    	puts(simtime_s, "generated #{data_frame}")
    	# save to DB
    	for m in data_frame
    	  m.save();
    	end
    	# prevent database from growing too large for demo.
    	# TODO: would not do this in a long-lived application.
    	Measurement.destroy_by(updated_at: ...(2.minutes.ago) );
  	sleep(1);
  	simtime_s = simtime_s + SIM_TIME_PER_SECOND;
    end
  end
  
  
end
