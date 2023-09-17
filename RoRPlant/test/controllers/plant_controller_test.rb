require "test_helper"

class PlantControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get plant_index_url
    assert_response :success
  end

  test "should get start_synth" do
    get plant_start_synth_url
    assert_response :success
  end

  test "should get stop_synth" do
    get plant_stop_synth_url
    assert_response :success
  end
end
