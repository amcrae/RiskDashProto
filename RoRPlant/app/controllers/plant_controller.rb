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
	  SELECT level, id, segtype, shortname, parent_id
	  FROM cte_connect_by
	  ORDER BY connect_by_path
    HEREDOC
    # 	  ORDER BY connect_by_path
    # level, connect_by_path path
    plain_sql = " SELECT id, segtype, shortname, parent_id from segments ORDER BY id"
    
    @seg_tree = Segment.find_by_sql(hierarchy_sql)
    Rails.logger.info("**************** got data")

  end

  def start_synth
  end

  def stop_synth
  end
end
