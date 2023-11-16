# frozen_string_literal: true

require_relative 'sensible_headers'

class CustomHeader
  include SensibleHeaders

  HEADER_NAME = "X-Plant-Custom-Bits";

  def initialize(app, *others)
    @app = app
    @unique_args = others or []
    Rails.logger.info("CustomHeader initialised for" + (app.to_s));
    Rails.logger.info("CustomHeader others args == " + (@unique_args.to_s))
  end

  def call(env)
    subset = env.select { |k, _v| k.start_with? 'HTTP_' };
    Rails.logger.info("CustomHeader called for " + subset.to_s)

    ext_to_app_mappings = Rails.application.config_for(:authorisation)[:provider_to_app]
    Rails.logger.info("Got role config info: " + ext_to_app_mappings.to_s)

    req = Rack::Request.new(env)
    # Change to request

    sesh = env['rack.session']
    s = ""
    for k, v in sesh
      s = s + "#{k}=#{v}, "
    end
    Rails.logger.info("sesh hash is #{s}")
    
    # req.each_header do |k, _v|
    #  Rails.logger.info("got header #{k}")
    # end
    reconstructed = reconstruct_headers(env)
    print "reconstructed headers == ", reconstructed, "\n"
    print "all caps found? ", reconstructed["DNT"], "\n"
    print "title case found? ", reconstructed["Dnt"], "\n"
    print "lower case found? ", reconstructed["dnt"], "\n"

    if req.has_header?(CustomHeader::HEADER_NAME) || reconstructed.has_key?(CustomHeader::HEADER_NAME) then
      Rails.logger.info("CustomHeader detected custom request header == #{reconstructed[CustomHeader::HEADER_NAME]}")
    else
      nval = "Request CustomHeader calc at " + Time.now().to_s()
      req.set_header(CustomHeader::HEADER_NAME, nval)
      Rails.logger.info("CustomHeader set custom request header == #{nval}")
    end
    
    sesh[:FOO] = "Bar"

    status, headers, body = @app.call(env)

    # change to response
    res = Rack::Response.new(body, status, headers)
    nval = "Response CustomHeader #{@unique_args} calc at " + Time.now().to_s()
    res.add_header(CustomHeader::HEADER_NAME, nval)

    [res.status, res.headers, res.body]
  end
end
