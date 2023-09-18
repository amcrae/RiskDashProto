require "test_helper"

class SynthControllerTest < ActionDispatch::IntegrationTest
  test "should get restart_synth" do
    get synth_restart_synth_url
    assert_response :success
  end

  test "should get stop_synth" do
    get synth_stop_synth_url
    assert_response :success
  end
end
