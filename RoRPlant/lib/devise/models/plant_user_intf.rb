# frozen_string_literal: true

require_relative '../../app_user_intf'

module PlantUserIntf
  include HeaderAuthentication::AppUserIntf
  
  def load_app_user_by_upn(upn)
    # puts "user_from_upn"
    return User.find_by(email: upn)
  end

  def get_upn_from_app_user(account)
    # puts "upn_from_user"
    if account.is_a?(Hash) then
      return account[:email]
    elsif account.is_a?(User) then
      return account.email
    end

    raise TypeError.new("Unexpected user account type #{account.class}")
  end

  def app_user_needs_headerauth?(account)
    return account.auth_type == 'EXTERNAL'
  end

  @@ext_to_native_role = ->(ext_name) {
    # puts ext_name, @@role_mapping
    if ext_name.include?('_') then
      file_key = ext_name.upcase.to_sym
    else 
      file_key = ext_name.to_sym
    end
    if @@role_mapping.has_key?(file_key) then
      return @@role_mapping[file_key][0]
    else
      return nil
    end
  }

  def set_app_user_roles(ext_role_array, account)
    @@role_mapping ||= Rails.application.config_for(:authorisation)[:provider_to_app];
    puts "ext_role_array == #{ext_role_array}"
    native_roles = ext_role_array.map(&@@ext_to_native_role)
    native_roles.select! { |x| x != nil };
    puts "native roles := #{native_roles}"
    # In this basic user model they only had 1 role.
    account.role_name = native_roles[0]
  end

  def create_app_user_from_template(user_info)
    if user_info[:ext_roles_array].size == 0 then
      return nil
    end
    
    init_pw = Digest::SHA1.hexdigest(Random.bytes(8));
    account = User.new(
      auth_type: "EXTERNAL", # authentication continues to be by headers
      email: user_info[:user_attributes]['mail'], 
      full_name: user_info[:user_attributes]['fullname'],
      password: init_pw # Not used due to external auth, but cannot be NULL.
    );
    return account;
  end

  def update_app_user(user_info, account)
    Rails.logger.debug("update_app_user #{account.email} with #{user_info[:user_attributes]}.")
    account.full_name = user_info[:user_attributes]['fullname']
  end
  
end
