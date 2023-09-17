class SegmentConnectionsController < ApplicationController
  before_action :set_segment_connection, only: %i[ show edit update destroy ]

  # GET /segment_connections or /segment_connections.json
  def index
    @segment_connections = SegmentConnection.all
  end

  # GET /segment_connections/1 or /segment_connections/1.json
  def show
  end

  # GET /segment_connections/new
  def new
    @segment_connection = SegmentConnection.new
  end

  # GET /segment_connections/1/edit
  def edit
  end

  # POST /segment_connections or /segment_connections.json
  def create
    @segment_connection = SegmentConnection.new(segment_connection_params)

    respond_to do |format|
      if @segment_connection.save
        format.html { redirect_to segment_connection_url(@segment_connection), notice: "Segment connection was successfully created." }
        format.json { render :show, status: :created, location: @segment_connection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @segment_connection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /segment_connections/1 or /segment_connections/1.json
  def update
    respond_to do |format|
      if @segment_connection.update(segment_connection_params)
        format.html { redirect_to segment_connection_url(@segment_connection), notice: "Segment connection was successfully updated." }
        format.json { render :show, status: :ok, location: @segment_connection }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @segment_connection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /segment_connections/1 or /segment_connections/1.json
  def destroy
    @segment_connection.destroy

    respond_to do |format|
      format.html { redirect_to segment_connections_url, notice: "Segment connection was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_segment_connection
      @segment_connection = SegmentConnection.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def segment_connection_params
      params.fetch(:segment_connection, {})
    end
end
