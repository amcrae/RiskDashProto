# frozen_string_literal: true

require 'digest'
require 'base64'
require 'json'
require 'open-uri'
require_relative '../../mock_header_authentication'

# Subclass of Warden Strategy (via Devise) which provides custom functions
# for verifying signatures of the homebrewed symmetric key signature 
# scheme developed for testing.
class MockHeaderStrategy < Devise::Strategies::Base
  include HeaderAuthentication
  extend MockHeaderAuthentication

  @@role_mapping = nil
  # a particular constructor sig is expected by Warden
  def initialize(*args)
    super(*args)
    #@impl_class = MockHeaderAuthentication
    #@impl = @impl_class.new();
    configure_functions("Mock")
    @@role_mapping ||= Rails.application.config_for(:authorisation)[:provider_to_app];
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    HeaderAuthentication.add_to_warden_method(self, config_name)
  end

end
