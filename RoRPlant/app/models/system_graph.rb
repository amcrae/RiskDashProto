require "observer"

class SystemGraph
    include Observable

  class SysNode
    include Observable
    attr_accessor :seg, :data
    def initialize(seg, data={})
        @seg = seg
        @data = data
    end
    
    def to_s()
        "SysNode(#{@seg},#{@data})"
    end
  end
  
  class SysEdge
    include Observable
    attr_accessor :conn, :data
    def initialize(conn, data={})
        @conn = conn
        @data = data
    end
    def to_s()
        "SysEdge(#{@conn},#{@data})"
    end
  end

  attr_accessor :nodes, :edges

  def initialize()
    @nodes = []
    @edges = []
    @gobjects_by_uuid = {}  # graph objects by the UUID of the system entity they hold.
    @nodes_by_uuid = {}
  end

  def to_s()
    return "SystemGraph#{self.object_id}(Nodes:#{@nodes},Edges:#{@edges})"
  end

  def uuid_to_object(uuid)
    if @gobjects_by_uuid.has_key?(uuid) then 
        return @gobjects_by_uuid[uuid]
    end
    return nil
  end

  def add_node(segment, data={})
    """ Return true if it was added,
          False if the uuid matches an object already in the graph.
    """ 
    if @gobjects_by_uuid.has_key?(segment.uuid) then
      return false
    end
    n = SysNode.new(seg=segment,data=data)
    @nodes.push(n)
    @nodes_by_uuid[segment.uuid] = n
    @gobjects_by_uuid[segment.uuid] = segment
    return true
  end

  def remove_node(segment)
    node = @gobjects_by_uuid[segment.uuid]
    @gobjects_by_uuid.delete(segment.uuid)
    @nodes_by_uuid.delete(segment.uuid)
    @nodes.delete(node)
  end

  def find_node(uuid:nil, segment:nil)
    if (uuid==nil) == (segment==nil) then
      raise ArgumentError.new("Must have either Segment object or the uuid, not both")
    end
    if uuid != nil then
      return @nodes_by_uuid[uuid]
    elsif segment!=nil then
      return @nodes_by_uuid[segment.uuid]
    end
  end

  def add_edge(seg_conn, data={})
    edge = @gobjects_by_uuid[seg_conn.uuid]
    puts edge
    if edge != nil then 
        return 
    end
    edge = SysEdge.new(seg_conn, data)
    @edges.push(edge)
    @gobjects_by_uuid[seg_conn.uuid] = edge
  end
  
  def find_edge_by_ends(from_seg, to_seg)
    for c in @edges
        if c.conn.from_seg == from_seg and c.conn.to_seg == to_seg
            return c
        end
    end
    return nil
  end

  def out_edges(segment)
    answer = []
    for c in @edges
        if c.conn.from_seg.uuid == segment.uuid
            answer.push(c)
        end
    end
    return answer
  end

  def in_edges(segment)
    answer = []
    for c in @edges
        if c.conn.to_seg.uuid == segment.uuid
            answer.push(c)
        end
    end
    return answer
  end


  def SystemGraph.load_dependencies_graph(output_segment_uuid)
    g = SystemGraph.new()
    discovery_queue  = []
    target = Segment.find_by(uuid: output_segment_uuid)
    discovery_queue.push(target)
    seg_ids = {}
    while discovery_queue.length>0
        seg = discovery_queue.shift();
        g.add_node(seg)
        seg_ids[seg.id] = true
        if seg.parent_id != nil and !seg_ids.has_key?(seg.parent_id) then
            g.add_node(seg.parent)
            seg_ids[seg.parent.id] = true
        end
        intos = SegmentConnection.where(to_segment_id: seg.id)
        puts intos
        for link in intos
           puts link
           g.add_edge(link);
           discovery_queue.push(link.from_seg);
        end
    end
    return g;
  end

end

