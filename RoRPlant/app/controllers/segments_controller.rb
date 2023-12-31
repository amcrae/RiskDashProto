class SegmentsController < ApplicationController
  before_action :set_segment, only: %i[show edit update destroy]

  # GET /segments or /segments.json
  def index
    @segments = Segment.all.accessible_by(current_ability)
  end

  # GET /segments/1 or /segments/1.json
  def show
  end

  # GET /segments/new
  def new
    @segment = Segment.new
  end

  # GET /segments/1/edit
  def edit
  end

  # POST /segments or /segments.json
  def create
    @segment = Segment.new(segment_params)
    authorize! :create, @segment

    respond_to do |format|
      if @segment.save
        format.html { redirect_to segment_url(@segment), notice: "Segment was successfully created." }
        format.json { render :show, status: :created, location: @segment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @segment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /segments/1 or /segments/1.json
  def update
    authorize! :write, @segment
    respond_to do |format|
      if @segment.update(segment_params)
        format.html { redirect_to segment_url(@segment), notice: "Segment was successfully updated." }
        format.json { render :show, status: :ok, location: @segment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @segment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /segments/1 or /segments/1.json
  def destroy
    @segment.destroy
    authorize! :delete, @segment
    respond_to do |format|
      format.html { redirect_to segments_url, notice: "Segment was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_segment
    @segment = Segment.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def segment_params
    # params.fetch(:segment, {})
    params.require(:segment).permit(:shortname, :segtype, :operational)
  end
end
