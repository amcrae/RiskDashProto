require "application_system_test_case"

class SegmentConnectionsTest < ApplicationSystemTestCase
  setup do
    @segment_connection = segment_connections(:one)
  end

  test "visiting the index" do
    visit segment_connections_url
    assert_selector "h1", text: "Segment connections"
  end

  test "should create segment connection" do
    visit segment_connections_url
    click_on "New segment connection"

    click_on "Create Segment connection"

    assert_text "Segment connection was successfully created"
    click_on "Back"
  end

  test "should update Segment connection" do
    visit segment_connection_url(@segment_connection)
    click_on "Edit this segment connection", match: :first

    click_on "Update Segment connection"

    assert_text "Segment connection was successfully updated"
    click_on "Back"
  end

  test "should destroy Segment connection" do
    visit segment_connection_url(@segment_connection)
    click_on "Destroy this segment connection", match: :first

    assert_text "Segment connection was successfully destroyed"
  end
end
