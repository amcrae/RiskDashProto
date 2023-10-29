class PlantController < ApplicationController

  # http_basic_authenticate_with name: "admin", password: "super", except: [:index, :show]

  def index
    @usr_signed_in = user_signed_in?
    @cur_usr = nil || current_user()

    hierarchy_sql = <<~HEREDOC
      WITH RECURSIVE cte_connect_by AS ( 
         SELECT 1 AS level, CAST( ('/' || shortname) AS VARCHAR(4000)) AS connect_by_path, s.* 
           FROM segments s WHERE id = 1
         UNION ALL
         SELECT level + 1 AS level, (connect_by_path || '/' || s.shortname) AS connect_by_path, s.* 
           FROM cte_connect_by r INNER JOIN segments s ON  r.id = s.parent_id
      )
      SELECT level, cte_connect_by.id, segtype, operational, cte_connect_by.shortname, parent_id, connect_by_path, 
      	 asset_id, assets.uuid as "asset_uuid", assets.shortname as "asset_name", assets.asset_type, assets.readiness
      FROM cte_connect_by LEFT OUTER JOIN assets ON cte_connect_by.asset_id = assets.id
      ORDER BY connect_by_path
    HEREDOC
    
    # plain_sql = " SELECT id, segtype, shortname, parent_id from segments ORDER BY id"
    
    # @seg_tree = Segment.find_by_sql(hierarchy_sql)
    res = Segment.connection.select_all(hierarchy_sql).to_a();
    tree_order = []
    for r in res do
      # puts r;
      seg = Segment.new(id:r["id"], shortname:r["shortname"], segtype:r["segtype"], operational:r["operational"], parent_id:r["parent_id"]);
      seg.level = r["level"]
      seg.path = r["connect_by_path"]
      asset = nil
      if r["asset_id"] != nil then
        Rails.logger.debug( { id: r["asset_id"], uuid: r["asset_uuid"], shortname: r["asset_name"], readiness: r["readiness"] } );
        asset = Asset.new(id: r["asset_id"], uuid: r["asset_uuid"], shortname: r["asset_name"], asset_type:r["asset_type"], readiness: r["readiness"] );
        Rails.logger.debug([asset, asset.id, asset.uuid].join(", "));
      end
      pair = {seg: seg, asset: asset};
      tree_order.push(pair);
    end
    @seg_tree = tree_order;

  end

end
