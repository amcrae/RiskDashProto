# frozen_string_literal: true

require 'devise'

# Functions as an adaptor between ID & Role tokens supplied in HTTP Headers
#  and the Devise framework for authentication in Rails.
# The order of events will be:
#   1. The Rack chain receives an HTTP request
#   2. Association of request with existing session is done by default SessionStore middleware.
#   3. The HeaderAuthentication middleware is called
#   3.1 The headers are checked to see if all required ones are present,
#   3.2 If all headers are there, a flag enabling header authentication is stored in session.
#   3.2.2 If NOT, make sure any persistent userid in session is logged out.
#   3.3 All token signatures are verified. May assume they remain valid for a limited period (e.g. 5 seconds).
#   3.4 The application UPN is extracted from the identity token and stored in session.
#   3.5 If the User does not exist, it is created from the the role+id tokens and saved to DB.
#   3.6 User's granted app roles are derived from the claims token, and are updated in ActiveRecord.
#   4. Warden calls 'valid?'. 
#   4.1 The answer already stored in session hash is returned.
#   5. Warden (may) call 'authenticate!'. 
#   5.1 The UPN is used to load the User instance from ActiveRecord.
#   5.2 The authenticate! method returns the authenticated User instance.
#   6. Warden sets the value of current_user and similar helper objects for use by authorisation.
#   7. Any authorisation framework which reads current_user (e.g. cancancan) or could use the UPN.
#
# The application-specific methods of verifying headers and loading User accounts
# are expected to be done by implementing classes that mixin HeaderAuthentication.
module HeaderAuthentication
  
  SESS_KEY_HA_STRATEGY_VALID = '_HAUTH_STRATEGY_VALID';

  SESS_KEY_HA_AUTH_UPN = '_HAUTH_UPN';

  SESS_KEY_HA_AUTH_USER = '_HAUTH_USER';

  # shared function to produce an authn strategy name from configured class.
  def self.class_config_to_strategy(subclass, config_name)
    # In case of permitting two different authentications for 
    # different resource paths, it may be necessary to distinguish
    # different parameters for the same class as different strategies.
    "#{subclass.to_s + "_" + config_name}".to_sym
  end
  
  def configure(app, configname)
    @app = app
    @config_name = configname
    all_config = Rails.application.config_for(:header_authentication)
    @header_config = all_config[:header_configs][@config_name.to_sym];
  end

  def cgize_name(real_name) 
    ("HTTP_" + real_name).upcase().sub('-', '_')
  end

  def call(env)
    req = Rack::Request.new(env);

    # reconstructed = reconstruct_headers(env)
    # sesh = req.session
    sesh = env['rack.session']

    # reloads config file each call.
    # TODO: remove as performance improvement, as changing params is infrequent after init development.
    all_config = Rails.application.config_for(:header_authentication)

    @header_config = all_config[:header_configs][@config_name.to_sym];
    extractions = @header_config[:header_extractions]

    @load_user_method = self.method(@header_config[:load_user_from_upn_function]);
    @new_user_method = self.method(@header_config[:create_user_from_template_function]);
    @set_roles_method = self.method(@header_config[:set_user_roles_function]);

    skip_resource = false
    for pathroot in @header_config[:ignore_resource_paths]
      if req.fullpath.downcase.start_with?(pathroot.downcase) then
        skip_resource = true
        break
      end
    end

    if skip_resource then
      # continue chain with no authentication requirement
      Rails.logger.error("No authentication required for #{req.fullpath}")
      # do nothing but allow rest of chain to run. No authentication.
      return @app.call(env)
    end

    # make sure nothing leftover from previous invocations if authentication fails.
    sesh.delete(SESS_KEY_HA_AUTH_UPN);
    sesh.delete(SESS_KEY_HA_AUTH_USER);

    if extractions.length == 0 then
      Rails.logger.error("No headers configured for HeaderAuthentication #{@config_name}")
      # do nothing but allow rest of chain to run. No authentication.
      return @app.call(env)
    end

    # step 3.1
    all_present = true

    for extraction_def in extractions
      header_name = extraction_def[:http_header]
      header_cgi_name = cgize_name(header_name)
      required = extraction_def[:required]; # YAML translated special string true to bool already.
      present = req.has_header?(header_cgi_name);
      all_present = all_present && (present || !required)
    end
    
    # step 3.2
    sesh[SESS_KEY_HA_STRATEGY_VALID] = all_present
    if !all_present then
      puts "HeaderAuthentication found no auth headers. Clearing auth session variables."
      clear_session_vars(req, sesh);
      return @app.call(env)
    end

    upn = nil
    user_template = {}
    user_roles = []

    # step 3.3
    all_verified = true
    extractions.each_with_index { |extraction_hash, i|
      header_name = extraction_hash[:http_header]
      puts "HeaderAuth step #{i} #{header_name}"
      header_cgi_name = cgize_name(header_name)
      present = req.has_header?(header_cgi_name);
      header_value = req.get_header(header_cgi_name);

      verified = verify_header(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
      # Only extraction operations which specify a verifier should affect whether all headers were verified.
      if verified != nil then
        all_verified = all_verified && verified;
      end
      if verified != false then
        res = extract_auth_info(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
        if @header_config[:user_upn_extraction_step].to_i == i then
          puts "HeaderAuth found upn"
          upn = res
        end
        if @header_config.has_key?(:validator_function_name) then
          validator = self.method(@header_config[:validator_function_name])
          passes = validator.call(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
          all_verified &= passes
        end  
      end
    }

    leave_calling_card = false

    # Step 3.4
    if all_verified && upn != nil then
      sesh[SESS_KEY_HA_AUTH_UPN] = upn;
      puts "HeaderAuthentication identified #{upn}."
      leave_calling_card = false || (@header_config[:return_auth_method_header] == true);

      # step 3.5
      account = @load_user_method.call(upn);
      if account == nil then
        account = @new_user_method.call(user_template);
        account.save()
      end
      
      # step 3.6
      @set_roles_method.call(user_roles, account)
      account.save()
      sesh[SESS_KEY_HA_AUTH_USER] = account
    else
      puts "HeaderAuthentication found no UPN. Clearing auth session variables."
      clear_session_vars(req, sesh);
    end

    # continue request handler chain
    status, headers, body = @app.call(env)

    if leave_calling_card then
      # for debugging, leave a calling card.
      res = Rack::Response.new(body, status, headers)
      res.add_header("X-Auth-HeaderAuthentication", "HeaderAuthentication #{@config_name}");
      return [res.status, res.headers, res.body]
    else
      return [status, headers, body]
    end
  end
  
  # Verification step can be done on all headers before extracting any info from them.
  def verify_header(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    header_name = extraction_hash[:http_header]
    header_cgi_name = cgize_name(header_name);
    present = req.has_header?(header_cgi_name);
    must_verify = extraction_hash.has_key?(:sig_verifier)
    if !present || !must_verify then
      return nil
    end

    token = req.get_header(header_cgi_name);

    signing_key = nil
    if extraction_hash.has_key?(:get_signing_key) 
      get_key_fun = self.method(extraction_hash[:get_signing_key])
      signing_key = get_key_fun.call(extraction_hash[:signing_key_args])
    end
    
    # Allow for multiple extractions on same header token without re-verifying same data.
    verified = nil
    if extraction_hash.has_key?(:sig_verifier) then
      verifier = self.method(extraction_hash[:sig_verifier]);
      if signing_key != nil and verifier != nil then
        verified = verifier.call(token, signing_key);
      end
    end
    return verified
  end

  def extract_auth_info(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    if extraction_hash.has_key?(:extraction_function_name) then
      extractor = self.method(extraction_hash[:extraction_function_name]);
      return extractor.call(i, extraction_hash, header_value, req, sesh, user_template, user_roles);
    end
  end

  def clear_session_vars(req, sesh)
    for vname in @header_config[:signout_erases_session_vars]
      if vname.start_with?('SESS_KEY_HA_') then
        varname = HeaderAuthentication.const_get(vname);
      else
        varname = vname;
      end
      Rails.logger.info("HeaderAuthentication is removing session var #{varname}.")
      sesh.delete(varname);
    end
  end

  def pk_passes_pinning?(epxected_host, expected_pk, request_ssl_info)
    # TODO: imitate https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning#openssl
  end

  # All custom extraction functions will be invokes with this signature.
  # This example does nothing but return the whole header value unmodified.
  def nop(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    return header_value
  end

  # This centralises the (short) work of supplying 
  #   the strategy implementation into Devise when it asks.
  # A class method expected to be called from all subclasses.
  # It has to be called before an instance of the subclass is created.
  # Written as a lambda to avoid RuboCop warning of defs inside defs.
  # Parameters: 
  #   subclass: The Class object of the implementation.
  #   configname: The name of the parameter set that will be used from `header_authentication.yml`.
  @@add_to_warden = ->(subclass, configname) {
    # Check whether header-based authentication should be used
    # then identify the relevant user
    strategy_name = HeaderAuthentication::class_config_to_strategy(subclass, configname)
    Rails.logger.info("adding auth strategy #{strategy_name} ...")

    Warden::Strategies.add(strategy_name) do 
      def valid? 
        # code here to check whether to try and authenticate using this strategy; 
        answer = session.has_key?(SESS_KEY_HA_STRATEGY_VALID) && session[SESS_KEY_HA_STRATEGY_VALID]
        Rails.logger.info("header_authentication. strategy valid? #{answer}.")
        return answer
      end 
    
      def authenticate! 
        # code here for doing authentication;
        # if successful, call  
        Rails.logger.debug("header_authentication.UPN?")
        if session.has_key?(SESS_KEY_HA_AUTH_UPN) \
          && session[SESS_KEY_HA_AUTH_UPN] != nil \
          && session[SESS_KEY_HA_AUTH_USER] != nil \
        then
          upn = session[SESS_KEY_HA_AUTH_UPN]
          user = session[SESS_KEY_HA_AUTH_USER]
          if user != nil then 
            Rails.logger.info("HeaderAuthentication replied to Warden with #{upn}.")
            return success!(user)
          end
        end
        message = "Could not obtain User from session variable #{SESS_KEY_HA_AUTH_UPN}"
        fail!(message) # where message is the failure message 
      end 
    end 
  }
  
end
