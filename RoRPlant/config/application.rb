require_relative "boot"

require "rails/all"

require_relative '../lib/custom_header'
require_relative '../lib/mock_proxy'
require_relative '../lib/header_authentication'
require_relative '../lib/mock_header_authentication'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RoRPlant
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # config.session_store :cache_store

    # custom application setting to keep middleware and GUI consistent.
    # allowed values are :PROXY_ONLY, :PROXY_OR_APP, :APP_ONLY
    config.custom_authentication = :PROXY_ONLY

    config.middleware.insert_before ActionDispatch::Static, Rack::BounceFavicon

    config.middleware.insert_after Rack::Head, MockProxy

    # config.middleware.insert_after MockProxy, CustomHeader, "extra arg1", "arg2"
    # config.middleware.insert_after Rack::Head, CustomHeader, "unique args", "foo"
    if [:PROXY_ONLY, :PROXY_OR_APP].include?(Rails.configuration.custom_authentication) then
      config.middleware.insert_after MockProxy, MockHeaderAuthentication, "Mock"
    end

    config.active_job.queue_adapter = :delayed_job
    
    config.streamer_thread = nil

    config.before_initialize do
      # initialization code goes here
      MockHeaderAuthentication::add_to_warden("Mock");
    end

  end
end
