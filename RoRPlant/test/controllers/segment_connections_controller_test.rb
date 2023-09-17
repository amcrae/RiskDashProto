require "test_helper"

class SegmentConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @segment_connection = segment_connections(:one)
  end

  test "should get index" do
    get segment_connections_url
    assert_response :success
  end

  test "should get new" do
    get new_segment_connection_url
    assert_response :success
  end

  test "should create segment_connection" do
    assert_difference("SegmentConnection.count") do
      post segment_connections_url, params: { segment_connection: {  } }
    end

    assert_redirected_to segment_connection_url(SegmentConnection.last)
  end

  test "should show segment_connection" do
    get segment_connection_url(@segment_connection)
    assert_response :success
  end

  test "should get edit" do
    get edit_segment_connection_url(@segment_connection)
    assert_response :success
  end

  test "should update segment_connection" do
    patch segment_connection_url(@segment_connection), params: { segment_connection: {  } }
    assert_redirected_to segment_connection_url(@segment_connection)
  end

  test "should destroy segment_connection" do
    assert_difference("SegmentConnection.count", -1) do
      delete segment_connection_url(@segment_connection)
    end

    assert_redirected_to segment_connections_url
  end
end
