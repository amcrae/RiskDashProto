# frozen_string_literal: true

require 'devise'

require_relative 'auth_scheme_intf'

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
  include AuthSchemeIntf

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

  def configure(configname)
    @@all_config ||= Rails.application.config_for(:header_authentication)
    @config_name = configname
    @header_config = @@all_config[:header_configs][@config_name.to_sym];
  end

  def configure_mw(app, configname)
    @app = app
    configure(configname)
  end

  def cgize_name(real_name) 
    ("HTTP_" + real_name.to_s).upcase().sub('-', '_')
  end

  def find_required_headers(req, sesh)
    # step 3.1
    all_present = true
    for header_name in self.class.required_header_names()
      header_cgi_name = cgize_name(header_name)
      present = req.has_header?(header_cgi_name);
      all_present = all_present && present
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
    user_info = {
      upn: nil,
      app_account: nil,
      user_attributes: {},
      ext_roles_array: []
    }

    # step 3.3
    all_verified = true
    user_data_found = {}
    header_order = self.class.required_header_names()
    Rails.logger.debug("header_order #{header_order}");
    for header_name in header_order
      # puts "HeaderAuth step #{i} #{header_name}"
      header_cgi_name = cgize_name(header_name)
      # present = req.has_header?(header_cgi_name); already checked
      header_value = req.get_header(header_cgi_name);

      verified = verify_header(header_name, @header_config, header_value, req, sesh, user_info)
      Rails.logger.debug("verify_header(#{header_name}..) returned #{verified}");
      # Only extraction operations which specify a verifier should affect whether all headers were verified.
      if verified != nil then
        all_verified = all_verified && verified;
      end
      if verified != false then
        # extraction functions are only called on verified headers.
        # step 3.6.1 will actually be done early, assumed to update user_roles object.
        found_user_data = self.class.get_user_details(
          header_name, @header_config, header_value, req, sesh, user_info
        )
        Rails.logger.debug("#{header_name} found #{found_user_data}")
        user_data_found.update(found_user_data)
      end
    end

    for header_name in header_order
      header_cgi_name = cgize_name(header_name)
      # present = req.has_header?(header_cgi_name); already checked
      header_value = req.get_header(header_cgi_name);
      validation = self.class.user_details_validator(
        header_name, header_value, user_info
      );
      # puts "#{header_name} validation #{validation}."
      if validation != nil then
        all_verified = all_verified && validation
      end
    end

    # puts "user_info == #{user_info}"

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
    # user_info[:account] = @load_user_method.call(user_info[:upn]);
    user_info[:account] = self.class.load_app_user_by_upn(user_info[:upn]);
    
    # 3.5.2 Check if the application permits the user to be authenticated externally.
    needs_header_auth = nil
    if (user_info[:account] != nil) then 
      # needs_header_auth = @user_needs_headerauth_method.call(user_info[:account]); 
      needs_header_auth = self.class.app_user_needs_headerauth?(user_info[:account])
    end
    if user_info[:account] != nil && needs_header_auth == false then
      # 3.5.3 If this User is not permitted external authentication, instantly return failed authentication.
      ts = Time.now()
      Rails.logger.warn(
        "#{ts} *** Valid external headers were provided for a non-external user #{user_info[:upn]}."
      );
      return nil
    else
      # 3.5.4 If the user does not exist, it is created from the the role+id tokens and saved to DB.
      if user_info[:account] == nil then
        user_info[:account] = self.class.create_app_user_from_template(user_info);
        # Application code may decide creation not permitted.
        if user_info[:account] != nil then 
          user_info[:account].update_tracked_fields!(env) # Devise trackable
        end
      else
        self.class.update_app_user(user_info, user_info[:account]);
      end

      # step 3.6.2  Done with updated user_roles object.
      # @set_roles_method.call(user_info[:ext_roles_array], user_info[:account])
      if user_info[:account] == nil then
        self.class.set_app_user_roles(user_info[:ext_roles_array], user_info[:account])
        user_info[:account].save()
      end
      return user_info[:account]
    end
  end 
  
  # Verification step can be done on all headers before extracting any info from them.
  def verify_header(header_name, config, header_value, req, sesh, user_info)
    header_cgi_name = cgize_name(header_name);
    present = req.has_header?(header_cgi_name);
    if !present then
      raise ArgumentError, "Tried to verify a header '#{header_name}' that is not present in request.";
    end

    token = req.get_header(header_cgi_name);

    signing_key = self.class.get_signature_verification_key(header_name, header_value, config)
    if signing_key == nil then
      # If no exception was raised it is because no signature is needed for this header.
      return nil # neither passed nor failed sig verification.
    end

    return self.class.verify_signed_value(
      header_name, token, signing_key, config
    );
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

  # ----
  # Implementation of Devise interface (valid? and authenticate!)
  # ----

  def valid? 
    # code here to check whether to try to authenticate using this strategy; 
    req = request(); # accessor via Warden common mixin.
    sesh = session();

    # step 3.2
    all_present, signout_detected = find_required_headers(req, sesh)
    sesh[SESS_KEY_HA_STRATEGY_VALID] = all_present
    
    answer = session.has_key?(SESS_KEY_HA_STRATEGY_VALID) && session[SESS_KEY_HA_STRATEGY_VALID] \
            && !request.path.include?("sign_in")
    Rails.logger.info("header_authentication. #{self.class.name} strategy valid? #{answer}.")
    return answer
  end 

  def authenticate! 
    # code here for doing authentication;
    Rails.logger.debug("header_authentication.UPN?")
    sesh = session()
    req = request()
    # make sure no UPN leftover from previous invocations if authentication fails.
    sesh.delete(SESS_KEY_HA_AUTH_UPN);
    user_info = identify_user(req, sesh);
    # puts "identify_user returned #{user_info}"
    if user_info && user_info[:upn] != nil
    then
      sesh[SESS_KEY_HA_AUTH_UPN] = user_info[:upn];
      account = get_user_account(user_info);
      # account = session[SESS_KEY_HA_AUTH_USER]
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
  

  # ----
  # Generic implementation of Rack middleware call(env).
  # ----

  def call(env)
    req = Rack::Request.new(env);

    # reconstructed = reconstruct_headers(env)
    # sesh = req.session
    sesh = env['rack.session']

    all_present = false
    signout_detected = false
    begin
      all_present, signout_detected = find_required_headers(req, sesh)
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
        old_upn = self.class.get_upn_from_app_user(old_account_obj)
        Rails.logger.info("External signout detected from old session of #{old_upn}, clearing auth session variables.")
        clear_session_vars(req, sesh);
      end
      return @app.call(env)
    end

    # In case of a previously externally-authorised user,
    # check if loss of headers has occurred or the headers user
    # has changed.
    userid_changed = false
    # This will duplicate some work also done later in the chain by `authenticate!`
    #  during initial authentication of a previously unauthenticated session.
    # However rechecking signatures of all requests will require this
    #  work to be done here anyhow, since `authenticate!` is only called once.
    user_info = identify_user(req, sesh); # performs sig checks too.
    if user_info != nil && user_info[:upn] != nil then
      Rails.logger.info("Middleware identified user as #{user_info}")
      req_upn = user_info[:upn].downcase();
      if sesh[SESS_KEY_HA_AUTH_UPN] != nil then
        # Session already existed.
        session_upn = sesh[SESS_KEY_HA_AUTH_UPN].downcase()
        current_session_user = self.class.load_app_user_by_upn(session_upn);
        ext_auth = self.class.app_user_needs_headerauth?(current_session_user)
        if ext_auth then 
          if req_upn == nil 
            userid_changed = true
            Rails.logger.info("External signout detected from old session of #{session_upn}, clearing auth session variables.")
          elsif req_upn != session_upn then
            userid_changed = true
            Rails.logger.warn("External headers show different user than current login of #{session_upn}, clearing auth session variables.")
          else
            Rails.logger.info("Refresh user details from token")
            refresh_user_details(user_info, current_session_user);
            sesh[SESS_KEY_HA_AUTH_USER] = current_session_user
          end
        end
      end
      if userid_changed
        # Effects controlled mainly by the string array in 
        #  'header_authentication.yaml' / {config} / signout_erases_session_vars:
        #  which must include 'warden.user.user.key' in order to
        #  emulate a logout without having access to the Devise helper for sign_out().
        clear_session_vars()
      end
    end
  
    # Continue request handling chain.
    return @app.call(env)
  end
  
  # Called from generic middleware `call` method and separated out as 
  # an option to be overridden by host application.
  def refresh_user_details(user_info, current_session_user)
    self.class.update_app_user(user_info, current_session_user);
    self.class.set_app_user_roles(user_info[:ext_roles_array], current_session_user);
    current_session_user.save()
  end
  
end
