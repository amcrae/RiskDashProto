# frozen_string_literal: true

class RiskAssessor

  def initialize(system_graph, output_uuid)
    @system_graph = system_graph;
    @out_node = @system_graph.find_node(uuid: output_uuid)
  end

  def gen_risk_assessment
    # TODO: ...
  end

end
