# frozen_string_literal: true

class AssetStatusController < ApplicationController  # ActionController::API
  before_action :authenticate_user!, except: %i[ show ]

  def sabotage
    begin
      asset_id = params[:asset_id];
      @asset = Asset.find(asset_id);
      authorize! :sabotage, @asset
      Rails.logger.debug("Gonna sabotage #{asset_id} !");
      @asset.readiness = 'FAILED';
      if @asset.segment then
        @segment = @asset.segment;
        @segment.operational = "OFFLINE";
        @segment.save()
      end
      @asset.save();
      render partial: "asset_status/show", locals: { asset: @asset }
    rescue CanCan::AccessDenied => e
      flash[:alert] = "Sabotage not permitted for user."
      render turbo_stream: [
        turbo_stream.replace("flash-messages", partial: "application/flash_message")
      ]
    end
  end

  def repair
    begin
      asset_id = params[:asset_id];
      @asset = Asset.find(asset_id);
      authorize! :repair, @asset
      Rails.logger.debug("Gonna repair #{asset_id} !");
      @asset.readiness = 'SERVICEABLE';
      @asset.save();  	
      if @asset.segment then
        @segment = @asset.segment;
        @segment.operational = "RUNNING";
        @segment.save()
      end
      render partial: "asset_status/show", locals: { asset: @asset }
    rescue CanCan::AccessDenied
      flash[:alert] = "Repair not permitted for user."
      render turbo_stream: [
        turbo_stream.replace("flash-messages", partial: "application/flash_message")
      ]
    end
  end

  def show
    asset_id = params[:asset_id];
    @asset = Asset.find(asset_id);    
    authorize! :read, @asset
  end
  
end
