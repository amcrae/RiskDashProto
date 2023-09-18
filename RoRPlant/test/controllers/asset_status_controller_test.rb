require "test_helper"

class AssetStatusControllerTest < ActionDispatch::IntegrationTest
  test "should get sabotage" do
    get asset_status_sabotage_url
    assert_response :success
  end

  test "should get repair" do
    get asset_status_repair_url
    assert_response :success
  end

  test "should get show" do
    get asset_status_show_url
    assert_response :success
  end
end
