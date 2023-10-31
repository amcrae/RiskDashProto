require "test_helper"

class RiskAssessmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  def test_save
    s = Segment.find_by(uuid: "1-2b01-0")
    otarg = MLocation.find_by(uuid: "1-2b01-2-1")
    r = RiskAssessment.new(
      uuid: '1-1-0', scope_segment_id: s.id, output_m_location_id: otarg.id, 
      out_price: 100.00, 
      out_currency: 'AUD', 
      start_time: Time.now, lookahead: '1 day', end_time: (Time.now() + 1.days()),
      calc_alg: 'basic_reliability'
    )
    r.save()
  end
  
end
