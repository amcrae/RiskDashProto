# frozen_string_literal: true

require 'digest'
require 'base64'
require 'json'
require 'open-uri'

require_relative 'header_authentication'
require_relative 'auth_scheme_intf'

# Class methods to implement functions specific to the 
# homebrewed symmetric key signature scheme developed for testing.
module MockHeaderAuthentication
  include HeaderAuthentication::AuthSchemeIntf

  def init_class_vars()
  end

  def required_header_names()
    ['x-auth-accesstoken', 'x-auth-identity', 'x-auth-data']
  end

  def pinned_verification_key(issuer_domain)
    pins = {
      'heyjust.trustus.com' => 'SECRET'
    }
    for k, v in pins.entries()
      if issuer_domain.start_with?(k)
        return v
      end
    end
    raise SecurityError, "No pinned cert matched the signature issuer."
  end

  def mock_key()
    Rails.logger.debug("Retrieval of real verification key would happen here.");
    'SECRET'
  end

  def issuer_domain(config)
    return URI.parse(config[:jwks_url]).host
  end

  def get_signature_verification_key(header_name, header_value, config)
    if header_name == 'x-auth-identity' then
      return nil;
    end

    issuer = issuer_domain(config)
    verification_key_key = { :issuer => issuer, :format => :PEM }.freeze()
    answer = Rails.cache.read(verification_key_key) 
    if answer == nil then
      answer = mock_key()
      Rails.cache.write(verification_key_key, answer)
    end
    return answer
  end

  def decode_homebrew(header_value)
    decoded = Base64.decode64(header_value);
    return decoded.split('|')
  end

  def mock_sig_validation(header_value, signing_key)
    # puts "mock_sig_validation"
    data, sig_rcvd = decode_homebrew(header_value) 
    prefixed = signing_key + '|' + data
    sig_recon = Digest::SHA1.hexdigest(prefixed).downcase();
    return (sig_rcvd.downcase() == sig_recon)
  end

  def pubkey_passes_pinning?(issuer_domain, received_pubkey)
    # TODO: imitate https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning#openssl
    return pinned_verification_key(issuer_domain) == received_pubkey
  end

  def verify_signed_value(header_name, header_value, signing_key, config)
    ok = mock_sig_validation(header_value, signing_key);
    domain = URI.parse(config[:jwks_url]).host
    ok = ok && pubkey_passes_pinning?(domain, signing_key);
    # puts "#{header_name} was #{if ok then 'OK' else 'BAD' end}."
    return ok;
  end

  def get_user_details(header_name, config, header_value, req, sesh, user_info)
    # puts "get_user_details #{header_name}"
    if header_name == 'x-auth-accesstoken' then
      return get_mock_user_template(header_name, config, header_value, req, sesh, user_info)
    elsif header_name == 'x-auth-identity' then
      user_info[:upn] = header_value
      return { upn: header_value }
    elsif header_name == 'x-auth-data' then
      return mock_extract_roles(header_name, config, header_value, req, sesh, user_info)
    else
      return {}
    end
  end

  # get user attributes from the mock access-token during prototyping.
  def get_mock_user_template(header_name, config, header_value, req, sesh, user_info)
    data, sig_rcvd = decode_homebrew(header_value);
    user_hash = JSON.parse(data);
    user_info[:user_attributes].update(user_hash);
    return user_hash
  end

  def query_directory_for_roles(config, upn)
    user_portion = upn.split('@')[0]
    uri = config[:directory_formula].sub("$USER", user_portion)
    body = nil
    if uri.starts_with?('file:')
      fpath = Pathname.new(uri[5..]).realpath()
      File.open fpath, "r" do |file|
        body = file.read()
      end
    else
      response = OpenURI.open_uri(uri)
      body = response.read();
      response.close();
    end
    groups = JSON.parse(body)
    answer = [];
    for grp_obj in groups["value"]
      answer.append(grp_obj["id"])
    end
    # puts "query_directory_for_roles returns #{answer}"
    return answer
  end

  # The assumption is the roles returned are the ones used by
  # this web application, so any mapping of external roles 
  # into native app roles must also happen here.
  def mock_extract_roles(header_name, config, header_value, req, sesh, user_info)
    # Can extrac roles from token if given.
    data, sig_rcvd = decode_homebrew(header_value) 
    user_hash = JSON.parse(data)
    if config[:use_directory_for_roles] then
      # Can query LDAP (etc) for more info.
      given_ext_roles = query_directory_for_roles(config, user_info[:upn])
    else 
      given_ext_roles = [] || user_hash['memberOf']
    end
    user_info[:ext_roles_array] = given_ext_roles
    # puts "given_ext_roles := #{given_ext_roles}"
    return { :ext_roles_array => given_ext_roles }
  end

  def user_details_validator(header_name, header_value, user_info)
    # puts "verify_match_to_template"
    # return header_value == user_info[:upn]
    if header_name == 'x-auth-identity' then
      return header_value == user_info[:upn] && \
             header_value == user_info[:user_attributes]["mail"];
    else
      return nil
    end
  end
  
end
