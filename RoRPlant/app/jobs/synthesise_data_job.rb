require "action_cable"

class SynthesiseDataJob < ApplicationJob
  queue_as :default
  
  attr_accessor :keep_running, :last_value

  # TODO: should be configurable by caller of perform. hardcoded for demo expediency.
  MLOC_DATA_DISTRIBUTIONS = [
    {mloc_uuid:"1-2dfe-2-1", avg_val:15.0, phase: 0.0, template:{qtype:"Current", uom:"A"} },
    # {mloc_uuid:"1-2f33-2-1", avg_val:14.9, phase: 7.3, template:{qtype:"Current", uom:"A"} }
  ]

  def initialize(*args)
    super(*args)
    @mlocs = {}
    MLOC_DATA_DISTRIBUTIONS.each do |mdist|
      mloc = MLocation.find_by(uuid:mdist[:mloc_uuid]);
      @mlocs[mloc.uuid] = mloc
    end
  end

  def run_in_thread()
    # Thread.new(4, 15.0) { |segid, loc_name, avg_val|
    #   perform(segid, loc_name, avg_val)
    # }
    Thread.new() {
      perform()
    }
  end


  def gen_measurement_for(mdist, simtime)
    phasedt = simtime + mdist[:phase];
    last_value = mdist[:avg_val] + (0.66*@n1d[phasedt] + 0.34*@n1d[phasedt*3.2] - 0.5);
    logger.debug(@last_value);
    mloc = @mlocs[mdist[:mloc_uuid]];
    mmsg = Measurement.new(
	mlocation_id: mloc.id,
	timestamp: Time.now,
	qtype: mdist[:template][:qtype],
	v: last_value,
	uom: mdist[:template][:uom]
    );
    return mmsg
  end

  
  def perform(*args)
    Rails.logger.debug("Init synth with #{args}")
    @keep_running = true
    # @loc_name = args[1]
    # @avg_val = args[2]
    @last_value = nil
    @last_message = nil
    
    @n1d = Perlin::Noise.new(1, {:interval=>24 } )

    Rails.logger.debug("Started synth")
    simtime = 0.0
    while self.keep_running and simtime<(1*24) do
    	data_frame = []
    	MLOC_DATA_DISTRIBUTIONS.each do |mdist|
    	  mmsg = gen_measurement_for(mdist, simtime)
	  SegmentMeasurementsChannel.send_measurement(mmsg)
    	  @last_message = mmsg
    	end
  	sleep(1)
  	simtime = simtime + 1.0/10
    end
  end
  
  
end
