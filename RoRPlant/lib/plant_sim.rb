# frozen_string_literal: true

# Simple simulation which propagates input values through the dependency network,
# maybe applying transformation specific to each component type along the way.
class PlantSim

  attr_accessor :sys_time

  def initialize(system_graph, sys_datetime, transfer_functions)
    super()
    @system_graph = system_graph;
    @sys_time = sys_datetime;
    @transfer_functions = transfer_functions
  end

  def load_latest_measurements(start_exclusive, stop_inclusive)
    measurements = Measurement.where("timestamp > ? and timestamp <= ? ", start_exclusive, stop_inclusive)
    max_time = start_exclusive
    latest_only = {};
    measurements.each do |m|
      if m.timestamp > max_time then max_time = m.timestamp end
      if !latest_only.has_key?(m.m_location) then
        latest_only[m.m_location] = m;
      else
        last = latest_only[m.m_location]
        if (last.timestamp < m.timestamp) && (last.qtype == m.qtype) then
          latest_only[m.m_location] = m;
        end
      end
    end
    return latest_only.values()
  end

  def sim_step(time_step)
    stop_inclusive = @sys_time + time_step;
    latest_measurements = load_latest_measurements(@sys_time, stop_inclusive)
    propagate_inputs(latest_measurements, stop_inclusive);
    # TODO: more?
    @sys_time = stop_inclusive
  end

  # If a predicted effect of an input would occur beyond the 
  # simulation time step horizon of _max_time, do not simulate 
  # that effect yet.
  def propagate_inputs(measurements, _max_time)
    for mmsg in measurements
      puts mmsg
      # TODO: ..
    end
  end

end
