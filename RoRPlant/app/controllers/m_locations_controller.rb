class MLocationsController < ApplicationController
  before_action :set_m_location, only: %i[ show edit update destroy ]

  # GET /m_locations or /m_locations.json
  def index
    @m_locations = MLocation.all
  end

  # GET /m_locations/1 or /m_locations/1.json
  def show
  end

  # GET /m_locations/new
  def new
    @m_location = MLocation.new
  end

  # GET /m_locations/1/edit
  def edit
  end

  # POST /m_locations or /m_locations.json
  def create
    @m_location = MLocation.new(m_location_params)

    respond_to do |format|
      if @m_location.save
        format.html { redirect_to m_location_url(@m_location), notice: "M location was successfully created." }
        format.json { render :show, status: :created, location: @m_location }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @m_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /m_locations/1 or /m_locations/1.json
  def update
    respond_to do |format|
      if @m_location.update(m_location_params)
        format.html { redirect_to m_location_url(@m_location), notice: "M location was successfully updated." }
        format.json { render :show, status: :ok, location: @m_location }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @m_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /m_locations/1 or /m_locations/1.json
  def destroy
    @m_location.destroy

    respond_to do |format|
      format.html { redirect_to m_locations_url, notice: "M location was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_m_location
      @m_location = MLocation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def m_location_params
      params.fetch(:m_location, {})
    end
end
