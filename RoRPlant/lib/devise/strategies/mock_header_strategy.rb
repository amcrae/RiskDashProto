# frozen_string_literal: true

require 'digest'
require 'base64'
require 'json'
require 'open-uri'
require_relative '../../header_authentication'

# Subclass of Warden Strategy (via Devise) which provides custom functions
# for verifying signatures of the homebrewed symmetric key signature 
# scheme developed for testing.
class MockHeaderStrategy < Devise::Strategies::Base

  @@role_mapping = nil

  def initialize
    super
    @impl = MockHeaderAuthentication.new()
    @@role_mapping ||= Rails.application.config_for(:authorisation)[:provider_to_app];
  end

  def valid? 
    @impl.valid?
  end

  def authenticate! 
    @impl.authenticate!
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    @@add_to_warden_method.call(self, config_name)
  end

end
