# frozen_string_literal: true

require_relative '../../mock_header_authentication'

# Subclass of Warden Strategy (via Devise) which provides 
# HTTP header-based authentication of the mock signature
# scheme via the extended modules.
class MockHeaderStrategy < Devise::Strategies::Base
  include HeaderAuthentication
  extend MockHeaderAuthentication
  extend PlantUserIntf

  @@role_mapping = nil

  # a particular constructor sig is expected by Warden
  def initialize(*args)
    super(*args)
    configure("Mock")
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    HeaderAuthentication.add_to_warden_method(self, config_name)
  end

end