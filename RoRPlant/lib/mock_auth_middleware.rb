# frozen_string_literal: true

require_relative 'mock_header_authentication'
require_relative 'devise/models/plant_user_intf'

# Subclass of Warden Strategy (via Devise) which provides custom functions
# for verifying signatures of the homebrewed symmetric key signature 
# scheme developed for testing.
class MockAuthMiddleware
  include HeaderAuthentication
  extend MockHeaderAuthentication
  extend PlantUserIntf
  
  def initialize(app, configname)
    configure_mw(app, configname);
  end

  # generic call implementation is mixed-in from HeaderAuthentication.

  # Called from inherited call and overridden here with identical code 
  # just as an implementation example.
  def refresh_user_details(user_info, current_session_user)
    self.class.update_app_user(user_info, current_session_user);
    self.class.set_app_user_roles(user_info[:ext_roles_array], current_session_user);
    current_session_user.save()
  end

end
