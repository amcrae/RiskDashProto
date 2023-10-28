# frozen_string_literal: true

require 'digest'
require 'base64'

# Subclass of HeaderAuthentication which provides custom functions
# for verifying signatures of the hombrewed symmetric key signature 
# scheme developed for testing.
class MockHeaderAuthentication
  include HeaderAuthentication

  def initialize(app, configname)
    configure(app, configname);
  end

  def mock_key(*args)
    return 'SECRET'
  end

  def decode_homebrew(header_value)
    decoded = Base64.decode64(header_value);
    return decoded.split('|')
  end

  def mock_sig_validation(header_value, signing_key)
    puts "mock_sig_validation"
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
    puts "verify_match_to_template"
    return header_value == user_template['upn']
  end

  def user_from_upn(upn)
    puts "user_from_upn"
    return User.find_by(email: upn)
  end

  def set_user_roles(role_array, account)
    # In this basic user model they only had 1 role.
    account.role_name = role_array[0]
  end

  def new_user(user_template) 
    init_pw = Digest::SHA1.hexdigest(Random.bytes(8));
    account = User.new(
      email: user_template['mail'], 
      full_name: user_template['fullname'], 
      password: init_pw
    );
    return account;
  end

  # To be called from Rails application-level config to install the custom auth functions.
  def self.add_to_warden(config_name)
    @@add_to_warden.call(self, config_name)
  end

end
