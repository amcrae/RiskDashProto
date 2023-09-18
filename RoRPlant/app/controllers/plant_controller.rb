class PlantController < ApplicationController

  def index
    hierarchy_sql = <<~HEREDOC
	  WITH RECURSIVE cte_connect_by AS ( 
	     SELECT 1 AS level, CAST( ('/' || shortname) AS VARCHAR(4000)) AS connect_by_path, s.* 
	       FROM segments s WHERE id = 1
	     UNION ALL
	     SELECT level + 1 AS level, (connect_by_path || '/' || s.shortname) AS connect_by_path, s.* 
	       FROM cte_connect_by r INNER JOIN segments s ON  r.id = s.parent_id
	  )
	  SELECT level, id, segtype, shortname, parent_id, connect_by_path
	  FROM cte_connect_by
	  ORDER BY connect_by_path
    HEREDOC
    # 	  ORDER BY connect_by_path
    # level, connect_by_path path
    plain_sql = " SELECT id, segtype, shortname, parent_id from segments ORDER BY id"
    
    # @seg_tree = Segment.find_by_sql(hierarchy_sql)
    res = Segment.connection.select_all(hierarchy_sql).to_a();
    Rails.logger.info("************* got data")
    Rails.logger.info(res)
    Rails.logger.info("***")
    tree_order = []
    for r in res do
      puts r;
      seg = Segment.new(id:r["id"], shortname:r["shortname"], segtype:r["segtype"], parent_id:r["parent_id"]);
      seg.level = r["level"]
      seg.path = r["connect_by_path"]
      tree_order.push(seg)
    end
    @seg_tree = tree_order

  end

end
