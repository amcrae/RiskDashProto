class AssetStatusController < ApplicationController  # ActionController::API

  def sabotage
  	asset_id = params[:asset_id];
  	Rails.logger.debug("Gonna sabotage #{asset_id} !");
  	@asset = Asset.find(asset_id);
  	@asset.readiness = 'FAILED';
  	if @asset.segment then
  		@segment = @asset.segment;
  		@segment.operational = "OFFLINE";
  		@segment.save()
  	end
  	@asset.save();
  	render partial: "asset_status/show", locals: {asset: @asset}
  end

  def repair
  	asset_id = params[:asset_id];
  	Rails.logger.debug("Gonna repair #{asset_id} !");
  	@asset = Asset.find(asset_id);
  	@asset.readiness = 'SERVICEABLE';
  	if @asset.segment then
  		@segment = @asset.segment;
  		@segment.operational = "RUNNING";
  		@segment.save()
  	end
  	@asset.save();  	
  	render partial: "asset_status/show", locals: {asset: @asset}
  end

  def show
  end
  
end
