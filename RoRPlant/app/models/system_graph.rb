# frozen_string_literal: true

require 'observer'

class SystemGraph

  include Observable

  class SysNode

    include Observable
    attr_accessor :seg, :data

    def initialize(seg, data: {})
      @seg = seg
      @data = data
    end

    def to_s
      "SysNode(seg=#{@seg.inspect()},data=#{@data}). "
    end

    def inspect
      return self.to_s()
    end
  end

  class SysEdge

    include Observable
    attr_accessor :conn, :data

    def initialize(conn, data: {})
      @conn = conn
      @data = data
    end

    def to_s
      "SysEdge(conn=#{@conn.inspect()},data=#{@data}). "
    end

    def inspect
      return self.to_s()
    end

  end

  attr_accessor :nodes, :edges

  def initialize
    @nodes = []
    @edges = []
    @gobjects_by_uuid = {}  # graph objects by the UUID of the system entity they hold.
    @nodes_by_uuid = {}
  end

  def to_s
    "SystemGraph#{object_id}(Nodes:#{@nodes},Edges:#{@edges})"
  end

  def uuid_to_object(uuid)
    return @gobjects_by_uuid[uuid] if @gobjects_by_uuid.has_key?(uuid)

    nil
  end

  def add_node(segment, data: {})
    return false if @gobjects_by_uuid.has_key?(segment.uuid)

    n = SysNode.new(segment, data: data)
    @nodes.push(n)
    @nodes_by_uuid[segment.uuid] = n
    @gobjects_by_uuid[segment.uuid] = segment
    true
  end

  def remove_node(segment)
    node = @gobjects_by_uuid[segment.uuid]
    @gobjects_by_uuid.delete(segment.uuid)
    @nodes_by_uuid.delete(segment.uuid)
    @nodes.delete(node)
  end

  def find_node(uuid: nil, segment: nil)
    raise ArgumentError, 'Must have either Segment object or the uuid, not both' if (uuid.nil?) == (segment.nil?)

    if !uuid.nil?
      @nodes_by_uuid[uuid]
    elsif !segment.nil?
      @nodes_by_uuid[segment.uuid]
    end
  end

  def add_edge(seg_conn, data: {})
    edge = @gobjects_by_uuid[seg_conn.uuid]
    puts edge
    return unless edge.nil?

    edge = SysEdge.new(seg_conn, data: data)
    @edges.push(edge)
    @gobjects_by_uuid[seg_conn.uuid] = edge
  end

  def find_edge_by_ends(from_seg, to_seg)
    for c in @edges
      return c if c.conn.from_seg == from_seg and c.conn.to_seg == to_seg
    end
    nil
  end

  def out_edges(segment)
    answer = []
    for c in @edges
      answer.push(c) if c.conn.from_seg.uuid == segment.uuid
    end
    answer
  end

  def in_edges(segment)
    answer = []
    @edges.each do |c|
      answer.push(c) if c.conn.to_seg.uuid == segment.uuid
    end
    answer
  end

  VISIT_ALL = lambda { |edge| 
    if edge then 
      return true
    end

    false
  }

  def bfs_node_visitor(start_seg, result, multivisit: false, edge_filter: VISIT_ALL, &block)
    raise ArgumentError, 'Need a code block to execute on each node' unless block_given?

    discovery_queue = []
    start = find_node(segment: start_seg)
    discovery_queue.push([nil, start])
    seg_ids = {}
    order = 0
    while discovery_queue.length > 0
      e, n = discovery_queue.shift
      next if seg_ids.has_key?(n.seg.uuid) && !multivisit

      seg_ids[n.seg.uuid] = order
      block.call(e, n, result)
      next_links = out_edges(n.seg)
      next_links.each { |link|
        n2 = find_node(segment: link.conn.to_seg)
        if edge_filter.call(link) then
          discovery_queue.push([link, n2])
        end
      }
      order += 1
    end
    result
  end

  def self.load_dependencies_graph(output_segment_uuid)
    g = SystemGraph.new
    discovery_queue = []
    target = Segment.find_by(uuid: output_segment_uuid)
    discovery_queue.push(target)
    seg_ids = {}
    while discovery_queue.length > 0
      seg = discovery_queue.shift
      g.add_node(seg)
      seg_ids[seg.id] = true
      if !seg.parent_id.nil? and !seg_ids.has_key?(seg.parent_id)
        g.add_node(seg.parent)
        seg_ids[seg.parent.id] = true
      end
      intos = SegmentConnection.where(to_segment_id: seg.id)
      for link in intos
        g.add_edge(link)
        discovery_queue.push(link.from_seg)
      end
    end
    return g
  end

end
