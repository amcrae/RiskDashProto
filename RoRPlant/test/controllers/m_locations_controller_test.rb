require "test_helper"

class MLocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @m_location = m_locations(:one)
  end

  test "should get index" do
    get m_locations_url
    assert_response :success
  end

  test "should get new" do
    get new_m_location_url
    assert_response :success
  end

  test "should create m_location" do
    assert_difference("MLocation.count") do
      post m_locations_url, params: { m_location: {  } }
    end

    assert_redirected_to m_location_url(MLocation.last)
  end

  test "should show m_location" do
    get m_location_url(@m_location)
    assert_response :success
  end

  test "should get edit" do
    get edit_m_location_url(@m_location)
    assert_response :success
  end

  test "should update m_location" do
    patch m_location_url(@m_location), params: { m_location: {  } }
    assert_redirected_to m_location_url(@m_location)
  end

  test "should destroy m_location" do
    assert_difference("MLocation.count", -1) do
      delete m_location_url(@m_location)
    end

    assert_redirected_to m_locations_url
  end
end
