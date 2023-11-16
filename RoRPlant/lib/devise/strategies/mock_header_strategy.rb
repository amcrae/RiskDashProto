# frozen_string_literal: true

require 'mock_header_authentication'
require 'devise/models/plant_user_intf'

# Subclass of Warden Strategy (via Devise) which provides 
# HTTP header-based authentication of the mock signature
# scheme via the extended modules.
class MockHeaderStrategy < Devise::Strategies::Base
  include HeaderAuthentication
  extend MockHeaderAuthentication
  extend PlantUserIntf

  # The constructor call of Warden strategies (env, scope)
  #  https://github.com/wardencommunity/warden/blob/88d2f59adf5d650238c1e93072635196aea432dc/lib/warden/proxy.rb#L381
  #  does not allow any place for class-specific constructor parameters.
  # There is no later opportunity to put instance-specific data into the strategy.
  # Therefore, for each set of proxy/query configuration parameters needed,
  #  a new class must be created as a subclass of Devise::Strategies::Base.
  # The name of that set of configuration parameters is then
  # synonymous with the class that uses it and must be used in configure().
  # This config name is first obtained when registering the class and is stored
  #  as a class variable here so it can be used during the constructor call.
  @@config_name = nil

  # a particular constructor sig is expected by Warden
  def initialize(*args)
    super(*args)
    configure(@@config_name)
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    @@config_name = config_name
    HeaderAuthentication.add_to_warden_method(self, config_name)
  end

end
