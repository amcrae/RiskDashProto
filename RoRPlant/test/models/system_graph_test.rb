# require "test_helper"
require_relative '../test_helper'
require 'set'

class SystemGraphTest < ActiveSupport::TestCase

    def test_outdegree()
        a = Segment.new(uuid:"1-0", shortname:"A", segtype:"LOGICAL", operational:Segment::OP_RUNNING)
        b = Segment.new(uuid:"1-1", shortname:"B", segtype:"LOGICAL", operational:Segment::OP_RUNNING)
        c = Segment.new(uuid:"1-3", shortname:"C", segtype:"LOGICAL", operational:Segment::OP_RUNNING)
        g = SystemGraph.new();
        changed = g.add_node(a, data:{foo:"bar"} );
        assert changed;

        changed = g.add_node(b);
        assert changed;

        changed = g.add_node(c);
        assert changed;

        ab = SegmentConnection.new(uuid:"1-9-1", shortname:"a-b", from_seg:a, to_seg:b);
        g.add_edge(ab,  data:{weight:1.0} )
        ac = SegmentConnection.new(uuid:"1-9-2", shortname:"a-c", from_seg:a, to_seg:c); 
        g.add_edge(ac, data:{weight:1.0} )

        assert g.nodes.size() == 3
        assert g.edges.size() == 2
        assert g.out_edges(a) != nil
        assert g.out_edges(a).size() == 2
        assert Set.new(g.out_edges(a).map( &proc {|x| x.conn})) == Set.new([ab,ac])

    end

    def test_load_dependencies()
        g = SystemGraph.load_dependencies_graph("1-2b01-2")
        puts "g is #{g}"
        assert g != nil
        assert g.nodes != nil
        assert g.nodes.size() == 9
        assert g.edges.size() == 6
    end

end
