require "application_system_test_case"

class MLocationsTest < ApplicationSystemTestCase
  setup do
    @m_location = m_locations(:one)
  end

  test "visiting the index" do
    visit m_locations_url
    assert_selector "h1", text: "M locations"
  end

  test "should create m location" do
    visit m_locations_url
    click_on "New m location"

    click_on "Create M location"

    assert_text "M location was successfully created"
    click_on "Back"
  end

  test "should update M location" do
    visit m_location_url(@m_location)
    click_on "Edit this m location", match: :first

    click_on "Update M location"

    assert_text "M location was successfully updated"
    click_on "Back"
  end

  test "should destroy M location" do
    visit m_location_url(@m_location)
    click_on "Destroy this m location", match: :first

    assert_text "M location was successfully destroyed"
  end
end
