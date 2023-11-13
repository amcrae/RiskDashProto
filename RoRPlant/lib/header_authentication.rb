# frozen_string_literal: true

require 'devise'

# Functions as an adaptor between ID & Role tokens supplied in HTTP Headers
#  and the Devise framework for authentication in Rails.
# In the below description the steps which require custom code have '+C'.
# The order of events will be:
#   1. The Rack chain receives an HTTP request
#   2. Association of request with existing session is done by default SessionStore middleware.
#   3. The HeaderAuthentication middleware is called
#   3.1 The headers are checked to see if all required ones are present, +C
#   3.2 If all headers are there, a flag enabling header authentication is stored in session.
#   3.2.2 If NOT, make sure any persistent userid in session is logged out.
#   3.3 All token signatures are verified. +C 
#       May assume they remain valid for a limited period (e.g. 5 seconds).
#   3.4 The application UPN is extracted from the identity token (+C) and stored in session.
#   3.5 A valid user account object is loaded.
#   3.5.1 Determine if an account exists for the UPN and load it. +C
#   3.5.2 Check if the application permits the user to be authenticated externally. +C
#   3.5.3 If this User is not permitted external authentication, instantly return failed authentication.
#   3.5.4 If the user does not exist, it is created from the the role+id tokens and saved to DB. +C
#   3.6 User account is granted any updated roles
#   3.6.1 User's granted app roles are derived from the claims token (+C),
#   3.6.2 The new list of roles are applied to the account (+C) and saved by ActiveRecord.
#   4. Warden calls 'valid?'. 
#   4.1 The answer already stored in session hash is returned.
#   5. Warden (may) call 'authenticate!'. 
#   5.1 The UPN is used to load the User instance from ActiveRecord.
#   5.2 The authenticate! method returns the authenticated User instance.
#   6. Warden sets the value of current_user and similar helper objects for use by authorisation.
#   7. Any authorisation framework which reads current_user (e.g. cancancan) or could use the UPN.
#
# Some assumptions about the host application are:
#  * The object representing a user account is assumed to inherit ActiveRecord::Base methods.
#  * The object representing a user account is assumed to implement the Devise Trackable module.
#  * Local traditional password authentication may also occur for some users, but...
#  * Each user must be authenticated by only one method for that user always.
# 
# The application-specific methods of verifying headers and loading User accounts
# are expected to be done by implementing classes that mixin HeaderAuthentication.
module HeaderAuthentication
  
  SESS_KEY_HA_STRATEGY_VALID = '_HAUTH_STRATEGY_VALID';

  SESS_KEY_HA_AUTH_UPN = '_HAUTH_UPN';

  SESS_KEY_HA_AUTH_USER = '_HAUTH_USER';

  @@all_config = nil

  # shared function to produce an authn strategy name from configured class.
  def self.class_config_to_strategy(subclass, config_name)
    # In case of permitting two different authentications for 
    # different resource paths, it may be necessary to distinguish
    # different parameters for the same class as different strategies.
    "#{subclass.to_s + "_" + config_name}".to_sym
  end

  def configure_functions(configname)
    @@all_config ||= Rails.application.config_for(:header_authentication)
    @config_name = configname
    @header_config = @@all_config[:header_configs][@config_name.to_sym];

    @load_user_method = self.class.method(@header_config[:load_user_from_upn_function]);
    @new_user_method = self.class.method(@header_config[:create_user_from_template_function]);
    @set_roles_method = self.class.method(@header_config[:set_user_roles_function]);
    @extract_upn_method = self.class.method(@header_config[:get_upn_from_user_function]);
    @user_needs_headerauth_method = self.class.method(@header_config[:user_needs_headerauth_function]);
  end

  def configure_mw(app, configname)
    @app = app
    configure_functions(configname)
  end

  def cgize_name(real_name) 
    ("HTTP_" + real_name).upcase().sub('-', '_')
  end

  def validate_headers(req, sesh)
    extractions = @header_config[:header_extractions]
    if extractions.length == 0 then
      emsg = "No header extractions configured for HeaderAuthentication #{@config_name}"
      Rails.logger.error(emsg)
      clear_session_vars(req, sesh);
      raise StandardError.new(emsg)
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
    
    # The session hash still has signed of previous ext authentication
    # however the auth headers are not longer being received.
    signout_detected = sesh.has_key?(SESS_KEY_HA_STRATEGY_VALID) && \
                       sesh[SESS_KEY_HA_STRATEGY_VALID] == true && \
                       sesh.has_key?(SESS_KEY_HA_AUTH_USER) &&
                       !all_present

    return all_present, signout_detected
  end

  def identify_user(req, sesh)
    # reloads config file each call.
    # TODO: remove as performance improvement, as changing params is infrequent after init development.
    # all_config = Rails.application.config_for(:header_authentication)

    # make sure no UPN leftover from previous invocations if authentication fails.
    sesh.delete(SESS_KEY_HA_AUTH_UPN);

    user_info = {
      upn: nil,
      app_account: nil,
      user_attributes: {},
      ext_roles_array: []
    }

    extractions = @header_config[:header_extractions]

    # step 3.3
    all_verified = true
    extractions.each_with_index { |extraction_hash, i|
      header_name = extraction_hash[:http_header]
      # puts "HeaderAuth step #{i} #{header_name}"
      header_cgi_name = cgize_name(header_name)
      present = req.has_header?(header_cgi_name);
      header_value = req.get_header(header_cgi_name);

      verified = verify_header(i, extraction_hash, header_value, req, sesh, user_info)
      # Only extraction operations which specify a verifier should affect whether all headers were verified.
      if verified != nil then
        all_verified = all_verified && verified;
      end
      if verified != false then
        # extraction functions are only called on verified headers.
        # step 3.6.1 will actually be done early, assumed to update user_roles object.
        res = extract_auth_info(i, extraction_hash, header_value, req, sesh, user_info)
        if @header_config[:user_upn_extraction_step].to_i == i then
          # puts "HeaderAuth found upn"
          # step 3.4
          user_info[:upn] = res
        end
        if @header_config.has_key?(:validator_function_name) then
          validator = self.class.method(@header_config[:validator_function_name])
          passes = validator.call(i, extraction_hash, header_value, req, sesh, user_info)
          all_verified &= passes
        end  
      end
    }

    leave_calling_card = false

    # Step 3.5
    if all_verified && user_info[:upn] != nil then
      ts = Time.now()
      Rails.logger.info("#{ts} *** HeaderAuthentication identified #{user_info[:upn]}.")
      # leave_calling_card = false || (@header_config[:return_auth_method_header] == true);
      return user_info
    else
      ts = Time.now()
      Rails.logger.info(
        "#{ts} HeaderAuthentication found no UPN from any valid headers.\
        Clearing auth session variables."
      )
      return nil
    end
  end

  # load the account object of the user, or create from header if unknown.
  def get_user_account(user_info)
    # 3.5.1 Determine if an account exists for the UPN and load it.
    user_info[:account] = @load_user_method.call(user_info[:upn]);
    # 3.5.2 Check if the application permits the user to be authenticated externally.
    needs_header_auth = nil
    if (user_info[:account] != nil) then 
      needs_header_auth = @user_needs_headerauth_method.call(user_info[:account]); 
    end
    if user_info[:account] != nil && needs_header_auth == false then
      # 3.5.3 If this User is not permitted external authentication, instantly return failed authentication.
      ts = Time.now()
      Rails.logger.warn(
        "#{ts} *** Valid external headers were provided for a non-external user #{user_info[:upn]}.\
          Abandoning request and clearing auth session variables."
      );
      return nil
    else
      # 3.5.4 If the user does not exist, it is created from the the role+id tokens and saved to DB.
      if user_info[:account] == nil then
        user_info[:account] = @new_user_method.call(user_info);
        user_info[:account].update_tracked_fields!(env) # Devise trackable
      end

      # step 3.6.2  Done with updated user_roles object.
      @set_roles_method.call(user_info[:ext_roles_array], user_info[:account])
      user_info[:account].save()
      return user_info[:account]
    end
  end 
  
  # Verification step can be done on all headers before extracting any info from them.
  def verify_header(i, extraction_hash, header_value, req, sesh, user_info)
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
      get_key_fun = self.class.method(extraction_hash[:get_signing_key])
      signing_key = get_key_fun.call(extraction_hash[:signing_key_args])
    end
    
    # Allow for multiple extractions on same header token without re-verifying same data.
    verified = nil
    if extraction_hash.has_key?(:sig_verifier) then
      verifier = self.class.method(extraction_hash[:sig_verifier]);
      if signing_key != nil and verifier != nil then
        verified = verifier.call(token, signing_key);
      end
    end
    return verified
  end

  def extract_auth_info(i, extraction_hash, header_value, req, sesh, user_info)
    if extraction_hash.has_key?(:extraction_function_name) then
      extractor = self.class.method(extraction_hash[:extraction_function_name]);
      return extractor.call(i, extraction_hash, header_value, req, sesh, user_info);
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

  # All custom extraction functions will be invoked with this signature.
  # This example does nothing but return the whole header value unmodified.
  def self.nop(i, extraction_hash, header_value, req, sesh, user_info)
    return header_value
  end

  # ----
  # Implementation of Devise interface (valid? and authenticate!)
  # ----

  def valid? 
    # code here to check whether to try to authenticate using this strategy; 
    req = request(); # accessor via Warden common mixin.
    sesh = session();
    skip = no_auth_resource?(req);
    if skip
      Rails.logger.error("No authentication required for #{req.fullpath}")
    end

    # step 3.2
    all_present, signout_detected = validate_headers(req, sesh)
    sesh[SESS_KEY_HA_STRATEGY_VALID] = all_present
    
    answer = session.has_key?(SESS_KEY_HA_STRATEGY_VALID) && session[SESS_KEY_HA_STRATEGY_VALID] \
            && !skip && !request.path.include?("sign_in")
    Rails.logger.info("header_authentication. strategy valid? #{answer}.")
    return answer
  end 

  def authenticate! 
    # code here for doing authentication;
    Rails.logger.debug("header_authentication.UPN?")
    sesh = session()
    req = request()
    user_info = identify_user(req, sesh);
    if user_info[:upn] != nil
    then
      sesh[SESS_KEY_HA_AUTH_UPN] = user_info[:upn];
      get_user_account(user_info);
      # account = session[SESS_KEY_HA_AUTH_USER]
      account = user_info[:account]
      sesh[SESS_KEY_HA_AUTH_USER] = account
      ts = Time.now()
      if account != nil then 
        Rails.logger.info("#{ts} *** HeaderAuthentication replied to Warden with account for #{user_info[:upn]}.")
        return success!(account)
      end
    end
    clear_session_vars(request, session);
    message = "Could not obtain User from session variable #{SESS_KEY_HA_AUTH_UPN}"
    fail!(message) # where message is the failure message 
  end 

  # This centralises the (short) work of supplying 
  #   the strategy implementation into Devise when it asks.
  # A class method expected to be called from all subclasses.
  # It has to be called before an instance of the subclass is created.
  # Parameters: 
  #   subclass: The Class object of the implementation.
  #   configname: The name of the parameter set that will be used from `header_authentication.yml`.
  def self.add_to_warden_method(subclass, configname)
    # Check whether header-based authentication should be used
    # then identify the relevant user
    strategy_name = HeaderAuthentication::class_config_to_strategy(subclass, configname)
    Rails.logger.info("adding auth strategy #{strategy_name} ...")

    # Refer https://github.com/wardencommunity/warden/wiki/Strategies
    Warden::Strategies.add(strategy_name, subclass);
  end
  
end
