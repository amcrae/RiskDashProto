# frozen_string_literal: true

require 'digest'
require 'base64'
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
class HeaderAuthentication
  include Devise::Controllers::Helpers

  SESS_KEY_HA_STRATEGY_VALID = '_HAUTH_STRATEGY_VALID';

  SESS_KEY_HA_AUTH_UPN = '_HAUTH_UPN';

  SESS_KEY_HA_AUTH_USER = '_HAUTH_USER';

  def initialize(app, configname)
    @app = app
    @config_name = configname
  end

  def cgize_name(real_name) 
    ("HTTP_" + real_name).upcase().sub('-', '_')
  end

  def call(env)
    req = Rack::Request.new(env);
    # reconstructed = reconstruct_headers(env)
    # sesh = req.session
    sesh = env['rack.session']

    # make sure nothing leftover from previous invocations if authentication fails.
    sesh.delete(SESS_KEY_HA_AUTH_UPN);
    sesh.delete(SESS_KEY_HA_AUTH_USER);

    all_config = Rails.application.config_for(:header_authentication)
    @header_config = all_config[:header_configs][@config_name.to_sym];
    extractions = @header_config[:header_extractions]

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
      header_cgi_name = cgize_name(header_name)
      present = req.has_header?(header_cgi_name);
      header_value = req.get_header(header_cgi_name);

      verified = verify_header(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
      # Only extraction operations which specify a verifier should affect whether all headers were verified.
      if verified != nil then
        all_verified = all_verified && verified;
      end
      if verified then
        res = extract_auth_info(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
        if @header_config[:user_upn_extraction].to_i == i then
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
    if all_verified then
      upn = user_template['upn'];
      sesh[SESS_KEY_HA_AUTH_UPN] = upn;
      puts "HeaderAuthentication identified #{upn}."
      leave_calling_card = true

      # step 3.5
      account = User.find_by(email: user_template['mail'])
      if account == nil then
        init_pw = Digest::SHA1.hexdigest(Random.bytes(8));
        account = User.new(
          email: user_template['mail'], 
          full_name: user_template['fullname'], 
          role_name: user_roles[0], 
          password: init_pw
        );
        account.save()
      end
      
      # step 3.6
      account.role_name = user_roles[0];
      account.save()
    else
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
    must_verify = (
      extraction_hash.has_key?(:sig_verifier) ||
      i == @header_config[:user_upn_extraction]
    )
    
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

  def nop(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    return header_value
  end

  def mock_key(*args)
    return 'SECRET'
  end

  def decode_homebrew(header_value)
    decoded = Base64.decode64(header_value);
    return decoded.split('|')
  end

  def mock_sig_validation(header_value, signing_key)
    data, sig_rcvd = decode_homebrew(header_value) 
    prefixed = signing_key + '|' + data
    sig_recon = Digest::SHA1.hexdigest(prefixed).downcase();
    return sig_rcvd.downcase() == sig_recon
  end

  # get user attributes from the mock access-token during prototyping.
  def get_user_template(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    data, sig_rcvd = decode_homebrew(header_value) 
    user_hash = JSON.parse(data)
    user_template.update(user_hash)
    return user_hash
  end

  def mock_extract_roles(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    data, sig_rcvd = decode_homebrew(header_value) 
    user_hash = JSON.parse(data)
    given_ext_roles = user_hash['memberOf']
    delta = given_ext_roles - user_roles
    user_roles.concat(delta)
    return given_ext_roles
  end

  def verify_match_to_template(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    return header_value == user_template['upn']
  end

  @@add_to_warden = ->() {
    # Check whether header-based authentication should be used
    # then identify the relevant user
    Rails.logger.info("adding header_authentication...")
    Warden::Strategies.add(:header_authentication) do 
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
        if session.has_key?(SESS_KEY_HA_AUTH_UPN) && session[SESS_KEY_HA_AUTH_UPN] != nil then
          upn = session[SESS_KEY_HA_AUTH_UPN]
          Rails.logger.info("header_authentication. find '#{upn}'...")
          user = User.find_by(email: upn)
          if user != nil then 
            puts "HeaderAuthentication replied to Warden with #{upn}."
            return success!(user)
          end
        end
        message = "Could not obtain User from header_auth_upn"
        fail!(message) # where message is the failure message 
      end 
    end 
  }

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden()
    @@add_to_warden.call()
  end

end
