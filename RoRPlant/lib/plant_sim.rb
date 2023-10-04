
class PlantSim
    # Simple simulation which propagates input values through the dependency network,
    # maybe applying transformation specific to each component type along the way.

    def initialize(system_graph, sys_datetime, transfer_functions)
        super()
        @system_graph = system_graph;
        @sys_time = sys_datetime;
        @transfer_functions = transfer_functions
    end

    def sim_step(time_step)
        stop_including = @sys_time + time_step;
        measurements = Measurement.where("timestamp > ? and timestamp <= ? ", @sys_time, stop_including)
        max_time = @sys_time

        latest_only = {}
        for m in measurements
            if m.timestamp > max_time then max_time  = m.timestamp end
            if !latest_only.has_key?(m.m_location ) then
                latest_only[m.m_location] = m;
            else
                last = latest_only[m.m_location]
                if (last.timestamp < m.timestamp) && (last.qtype == m.qtype) then
                    latest_only[m.m_location] = m;
                end
            end
        end
        
        propagate_inputs(latest_only.values, max_time);
        # TODO: ....
        @sys_time = stop_including
    end

    def propagate_inputs(measurements, max_time)

        for mmsg in measurements
            puts mmsg
            # TODO: ..

        end
    
    end


end
