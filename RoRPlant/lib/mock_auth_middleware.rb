# frozen_string_literal: true

require 'mock_header_authentication'
require 'devise/models/plant_user_intf'

class MockAuthMiddleware
  include HeaderAuthentication
  extend MockHeaderAuthentication
  extend PlantUserIntf
  
  def initialize(app, configname)
    configure_mw(app, configname);
  end

  def call(env)
    req = Rack::Request.new(env);

    # reconstructed = reconstruct_headers(env)
    # sesh = req.session
    sesh = env['rack.session']

    all_present = false
    signout_detected = false
    begin
      all_present, signout_detected = validate_headers(req, sesh)
    rescue StandardError => e
      res = Rack::Response.new("Web server configuration problem #{e}", 500, {})
      return [res.status, res.headers, res.body]
    end

    if !all_present then
      Rails.logger.info("HeaderAuthentication found no auth headers.")
      if signout_detected then
        old_account_obj = sesh[SESS_KEY_HA_AUTH_USER];
        # The :get_upn_from_user_function may be passed a Hash of the fields
        # instead of the original ActiveRecord account object,
        # due to web session state being serialised to storage.
        old_upn = @extract_upn_method.call(old_account_obj)
        Rails.logger.info("External signout detected from old session of #{old_upn}, clearing auth session variables.")
        clear_session_vars(req, sesh);
      end
      return @app.call(env)
    end

    # in case of a previously externally-authorised user
    # check if loss of headers has occurred or the headers user
    # has changed.
    user_changed = false
    user_info = identify_user(req, sesh);
    if user_info != nil && user_info[:upn] != nil
      req_upn = user_info[:upn].downcase();
      if sesh[SESS_KEY_HA_AUTH_UPN] != nil then
        session_upn = sesh[SESS_KEY_HA_AUTH_UPN].downcase()
        current_session_user = @load_user_method.call(session_upn)
        ext_auth = @user_needs_headerauth_method.call(current_session_user)
        if ext_auth then 
          if req_upn == nil 
            user_changed = true
            Rails.logger.info("External signout detected from old session of #{session_upn}, clearing auth session variables.")
          elsif req_upn != session_upn then
            user_changed = true
            Rails.logger.warn("External headers show different user than current login of #{session_upn}, clearing auth session variables.")
          end
        end
      end
      if user_changed
        clear_session_vars()
      end
    end
  
    return @app.call(env)
  end

end
