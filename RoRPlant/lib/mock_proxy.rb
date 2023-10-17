# frozen_string_literal: true

# A Rack middleware class which mocks presence of a proxy.
# It does this by
#    1. being told (e.g. by a rails controller) which JWTs to inject into which HTTP headers.
#    2. inserting these headers into each request.
# The original purpose is testing authentication and authorization middleware downstream in the chain.
class MockProxy
  include SensibleHeaders

  SESSION_VAR_CONFNAME = :"_mockproxyconfname"

  def initialize(app)
    @app = app
  end

  def call(env)
    @header_configs = Rails.application.config_for(:mock_proxy)[:header_configs]
    req = Rack::Request.new(env)
    # reconstructed = reconstruct_headers(env)

    Rails.logger.info("Full path==" + req.fullpath())

    # sesh = req.session
    sesh = env['rack.session']

    s = ""
    for k, v in sesh
      s = s + "#{k}=#{v}, "
    end
    Rails.logger.info("sesh hash is #{s}")

    # check if the request should be interecepted to establish a mock headers config.
    for conf_name in @header_configs.keys
      config = @header_configs[conf_name]

      if config.has_key?(:set_on_intercepted_path) then
        detect_path = config[:set_on_intercepted_path]
        if req.fullpath().include?(detect_path)
          sesh[MockProxy::SESSION_VAR_CONFNAME] = conf_name
        end

      elsif config.has_key?(:remove_on_intercepted_path) then
        detect_path = config[:remove_on_intercepted_path]
        if req.fullpath().include?(detect_path)
          sesh[MockProxy::SESSION_VAR_CONFNAME] = nil
        end
      end

    end

    # Rails.logger.info("sesh #{MockProxy::SESSION_VAR_CONFNAME} == #{sesh[MockProxy::SESSION_VAR_CONFNAME]}")
    if sesh.has_key?(MockProxy::SESSION_VAR_CONFNAME) && sesh[MockProxy::SESSION_VAR_CONFNAME] != nil
      conf_name = sesh[MockProxy::SESSION_VAR_CONFNAME]
      if conf_name != nil then set_headers(conf_name, req); end
    end

    # call remainder of chain
    status, headers, body = @app.call(env)

    # not altering response
    return [status, headers, body]
  end

  def set_headers(config_name, req)
    Rails.logger.info("setting headers for mock config #{config_name}")
    conf = @header_configs[config_name.to_sym]
    for n, v in conf[:header_values]
      req.set_header("HTTP_" + n.to_s, v)
      Rails.logger.info("set req header #{n} == #{v}")
    end
  end

end
