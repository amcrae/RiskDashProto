# frozen_string_literal: true

require_relative '../../mock_header_authentication'

# Subclass of Warden Strategy (via Devise) which provides 
# HTTP header-based authentication of the mock signature
# scheme via the extended modules.
class MockHeaderStrategy < Devise::Strategies::Base
  include HeaderAuthentication
  extend MockHeaderAuthentication
  extend PlantUserIntf

  # The constructor call of Warden strategies (env, scope)
  # https://github.com/wardencommunity/warden/blob/88d2f59adf5d650238c1e93072635196aea432dc/lib/warden/proxy.rb#L381
  # does not allow any place for class-specific constructor parameters.
  # A new concrete class must be created as a new Devise::Strategies::Base 
  # for each set of proxy/query configuration parameters needed.
  # The name of that set of configuration parameters is then
  # synonymous with the class that uses it and must be used in configure().
  @@config_name = nil

  @@role_mapping = nil
  
  # a particular constructor sig is expected by Warden
  def initialize(*args)
    super(*args)
    Rails.logger.debug("#{self.class.name} for config #{@@config_name} initializing with #{args}.")
    configure(@@config_name)
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    @@config_name = config_name
    HeaderAuthentication.add_to_warden_method(self, config_name)
  end

end
