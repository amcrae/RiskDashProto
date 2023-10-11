
class CustomHeader
    HEADER_NAME = "X-PLANT-CUSTOM-BITS";

    def initialize(app)
        @app = app
        Rails.logger.info("CustomHeader initialised for"+(app.to_s));
    end

    def call(env)
        Rails.logger.info("CustomHeader called for "+env.to_s)

        req = Rack::Request.new(env)
        # Change to request
        req.each_header do |k,v|
            Rails.logger.info("got header #{k}")
        end
        if req.has_header?(CustomHeader::HEADER_NAME)
            Rails.logger.info("CustomHeader detected custom request header == #{req.get_header(CustomHeader::HEADER_NAME)}")
        else
            nval = "Request CustomHeader calc at " + Time.now().to_s()
            req.set_header(CustomHeader::HEADER_NAME, nval)
            Rails.logger.info("CustomHeader set custom request header == #{nval}")
        end

        status, headers, body = @app.call(env)

        # change to response
        res = Rack::Response.new(body, status, headers)
        nval = "Response CustomHeader calc at " + Time.now().to_s()
        res.add_header(CustomHeader::HEADER_NAME, nval)

        [res.status, res.headers, res.body]
    end
end
