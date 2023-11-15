require_relative "boot"

require "rails/all"

# The suggestion of adding /lib into eager_load_paths
# will not take effect until after config block is over,
# however classes from /lib must be resolved during this block.
# A require() would fail but a require_relative() worked.
require_relative '../lib/mock_proxy'
require_relative '../lib/mock_auth_middleware'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RoRPlant
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.i18n.fallbacks = true
    config.i18n.fallbacks = [:en]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # config.eager_load_paths << Rails.root.join('lib')

    # config.session_store :cache_store

    # custom application setting to keep middleware and GUI consistent.
    # allowed values are :PROXY_ONLY, :PROXY_OR_APP, :APP_ONLY
    config.custom_authentication = :PROXY_OR_APP

    config.middleware.insert_before ActionDispatch::Static, Rack::BounceFavicon

    config.middleware.insert_after Rack::Head, MockProxy

    # config.middleware.insert_after MockProxy, CustomHeader, "extra arg1", "arg2"
    # config.middleware.insert_after Rack::Head, CustomHeader, "unique args", "foo"
    if [:PROXY_ONLY, :PROXY_OR_APP].include?(Rails.configuration.custom_authentication) then
      config.middleware.insert_before Warden::Manager, MockAuthMiddleware, "Mock"
    end

    config.active_job.queue_adapter = :delayed_job
    
    config.streamer_thread = nil
  end
end
