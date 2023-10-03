# require "test_helper"
require_relative '../test_helper'
require 'set'

class SystemGraphTest < ActiveSupport::TestCase

    def setup_diamond()
        @g = SystemGraph.new();

        @a = Segment.new(uuid:"1-0", shortname:"A", segtype:"LOGICAL", operational:Segment::OP_RUNNING)
        @b = Segment.new(uuid:"1-1", shortname:"B", segtype:"LOGICAL", operational:Segment::OP_RUNNING)
        @c = Segment.new(uuid:"1-3", shortname:"C", segtype:"LOGICAL", operational:Segment::OP_RUNNING)
        @d = Segment.new(uuid:"1-4", shortname:"D", segtype:"LOGICAL", operational:Segment::OP_RUNNING)

        changed = @g.add_node(@a, data:{foo:"bar"} );
        assert changed;

        changed = @g.add_node(@b);
        assert changed;

        changed = @g.add_node(@c);
        assert changed;

        @ab = SegmentConnection.new(uuid:"1-9-1", shortname:"a-b", from_seg:@a, to_seg:@b);
        @g.add_edge(@ab,  data:{weight:1.0} )
        @ac = SegmentConnection.new(uuid:"1-9-2", shortname:"a-c", from_seg:@a, to_seg:@c); 
        @g.add_edge(@ac, data:{weight:1.0} )

        changed = @g.add_node(@d);
        assert changed;
        @bd = SegmentConnection.new(uuid:"1-9-3", shortname:"b-d", from_seg:@b, to_seg:@d);
        @g.add_edge(@bd, data:{weight:1.0} )
        @cd = SegmentConnection.new(uuid:"1-9-4", shortname:"c-d", from_seg:@c, to_seg:@d);
        @g.add_edge(@cd, data:{weight:1.0} )

        assert @g.nodes.size() == 4
        assert @g.edges.size() == 4
    end

    def test_find_node()
        self.setup_diamond();
        should_be_nb = @g.find_node(uuid:@b.uuid)
        should_be_nc = @g.find_node(segment:@c)
        assert should_be_nb != nil
        assert should_be_nb.seg == @b
        assert should_be_nc != nil
        assert should_be_nc.seg == @c
    end

    def test_find_edge()
        self.setup_diamond();
        should_be_ab = @g.find_edge_by_ends(@a,@b)
        assert should_be_ab != nil
        assert should_be_ab.conn != nil
        assert should_be_ab.conn == @ab
    end

    def test_outdegree()
        self.setup_diamond();
        assert @g.out_edges(@a) != nil
        assert @g.out_edges(@a).size() == 2
        assert Set.new(@g.out_edges(@a).map( &proc {|x| x.conn})) == Set.new([@ab,@ac])

        assert @g.out_edges(@b) != nil
        assert @g.out_edges(@b).size() == 1

        assert @g.out_edges(@d) != nil
        assert @g.out_edges(@d).size() == 0
    end

    def test_indegree()
        self.setup_diamond();
        assert @g.in_edges(@d) != nil
        assert @g.in_edges(@d).size() == 2
        assert Set.new(@g.in_edges(@d).map( &proc {|x| x.conn})) == Set.new([@bd,@cd])
        assert @g.in_edges(@b) != nil
        assert @g.in_edges(@b).size() == 1
        assert @g.in_edges(@a) != nil
        assert @g.in_edges(@a).size() == 0
    end

    def test_bfs_nodes()
        self.setup_diamond();
        init_r = [];
        res = @g.bfs_node_visitor(@a, init_r, multivisit:false) { | e, n, r |
            r << "#{n.seg.uuid} via #{e ? e.conn.shortname : nil}."
        }
        assert res.size == 4
        assert res[3].starts_with?("1-4 ")
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
