# frozen_string_literal: true

require_relative 'header_authentication'

class MockAuthMiddleware


  def initialize(app, configname)
    super()
    configure(app, configname);
    @@role_mapping ||= Rails.application.config_for(:authorisation)[:provider_to_app];
  end

  def initialize(app, configname)
    # super(app, configname)
    @impl_class = MockHeaderAuthentication
    @impl = @impl_class.new().configure_mw(app, configname);
    @@role_mapping ||= Rails.application.config_for(:authorisation)[:provider_to_app];
  end

  def call(env)
    req = Rack::Request.new(env);

    # reconstructed = reconstruct_headers(env)
    # sesh = req.session
    sesh = env['rack.session']

    skip_resource = no_auth_resource?(req)
    if skip_resource then
      # continue chain with no authentication requirement
      Rails.logger.error("No authentication required for #{req.fullpath}")
      # do nothing but allow rest of chain to run. No authentication.
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