# frozen_string_literal: true

require 'mock_header_authentication'
require 'devise/models/plant_user_intf'

# Subclass of Warden Strategy (via Devise) which provides custom functions
# for verifying signatures of the homebrewed symmetric key signature 
# scheme developed for testing.
class MockHeaderStrategy < Devise::Strategies::Base
  include HeaderAuthentication
  extend MockHeaderAuthentication
  extend PlantUserIntf

  @@role_mapping = nil

  # a particular constructor sig is expected by Warden
  def initialize(*args)
    super(*args)
    configure_functions("Mock")
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    HeaderAuthentication.add_to_warden_method(self, config_name)
  end

end
