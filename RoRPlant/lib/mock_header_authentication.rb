# frozen_string_literal: true

require 'digest'
require 'base64'

# Subclass of HeaderAuthentication which provides custom functions
# for verifying signatures of the hombrewed symmetric key signature 
# scheme developed for testing.
class MockHeaderAuthentication
  include HeaderAuthentication

  @@role_mapping = nil

  def initialize(app, configname)
    configure(app, configname);
    @@role_mapping ||= Rails.application.config_for(:authorisation)[:provider_to_app];
  end

  def self.nop(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    return header_value
  end

  def self.mock_key(*args)
    return 'SECRET'
  end

  def self.decode_homebrew(header_value)
    decoded = Base64.decode64(header_value);
    return decoded.split('|')
  end

  def self.mock_sig_validation(header_value, signing_key)
    puts "mock_sig_validation"
    data, sig_rcvd = decode_homebrew(header_value) 
    prefixed = signing_key + '|' + data
    sig_recon = Digest::SHA1.hexdigest(prefixed).downcase();
    return sig_rcvd.downcase() == sig_recon
  end

  # get user attributes from the mock access-token during prototyping.
  def self.get_user_template(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    data, sig_rcvd = decode_homebrew(header_value) 
    user_hash = JSON.parse(data)
    user_template.update(user_hash)
    return user_hash
  end

  @@ext_to_native_role = ->(ext_name) {
    uc = ext_name.upcase.to_sym
    if @@role_mapping.has_key?(uc) then
      return @@role_mapping[uc][0]
    else
      return ext_name
    end
  }

  # The assumption is the roles returned are the ones used by
  # this web application, so any mapping of external roles 
  # into native app roles must also happen here.
  def self.mock_extract_roles(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    data, sig_rcvd = decode_homebrew(header_value) 
    user_hash = JSON.parse(data)
    given_ext_roles = user_hash['memberOf']
    given_native_roles = given_ext_roles.map(&@@ext_to_native_role)
    user_roles.clear()
    user_roles.concat(given_native_roles)
    return given_native_roles
  end

  def self.verify_match_to_template(i, extraction_hash, header_value, req, sesh, user_template, user_roles)
    puts "verify_match_to_template"
    return header_value == user_template['upn']
  end

  def self.user_from_upn(upn)
    puts "user_from_upn"
    return User.find_by(email: upn)
  end

  def self.upn_from_user(account)
    puts "upn_from_user"
    if account.is_a?(Hash) then
      return account[:email]
    elsif account.is_a?(User) then
      return account.email
    end

    raise TypeError.new("Unexpected user account type #{account.class}")
  end

  def self.user_has_ext_authn(account)
    return account.auth_type == 'EXTERNAL'
  end

  def self.set_user_roles(role_array, account)
    # In this basic user model they only had 1 role.
    account.role_name = role_array[0]
  end

  def self.new_user(user_template) 
    init_pw = Digest::SHA1.hexdigest(Random.bytes(8));
    account = User.new(
      auth_type: "EXTERNAL", # authentication continues to be by headers
      email: user_template['mail'], 
      full_name: user_template['fullname'],
      password: init_pw # Not used due to external auth, but cannot be NULL.
    );
    return account;
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    @@add_to_warden_method.call(self, config_name)
  end

end
