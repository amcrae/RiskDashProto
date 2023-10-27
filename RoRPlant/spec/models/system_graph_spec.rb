require 'rails_helper'

RSpec.describe SystemGraph, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"

  it "can be created empty" do
    g = SystemGraph.new()
    expect(g).not_to be_nil;
  end

  it "can be an empty graph and no accessors crash" do
    g = SystemGraph.new()
    a = Segment.new(uuid: 'a')
    b = Segment.new(uuid: 'b')
    r = g.to_s()
    expect(r).not_to be_nil;

    o = g.uuid_to_object(nil)
    expect(o).to be_nil;

    n = g.find_node(uuid: 'nonexistent')
    expect(n).to be_nil;

    e = g.find_edge_by_ends(a, b)
    expect(e).to be_nil;

    e = g.out_edges(a);
    expect(e).to be_empty # no outs

    e = g.in_edges(a);
    expect(e).to be_empty # no ins

    r = {}
    g.bfs_node_visitor a, r do |e, n, res|
      res[n] = true
    end
    expect(r).to be_empty

    subby = g.load_dependencies_graph(a)
    expect(subby.nodes).to be_empty;
    expect(subby.edges).to be_empty;
    
  end
  
end
